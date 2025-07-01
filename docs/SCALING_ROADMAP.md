# OneAlarm Scaling Roadmap

## 🎯 Overview

This document outlines the strategic scaling plan for OneAlarm using Supabase and cron jobs, based on the updated capacity analysis showing potential for 3,750+ alarms/hour.

## 📊 Current State

- **Current Capacity**: 30 alarms/hour (720/day)
- **Maximum Theoretical**: 3,750 alarms/hour (90,000/day)
- **Improvement Potential**: 125x capacity increase
- **Bottleneck**: Processing time (3-4 minutes per alarm), not platform limits
- **Audio Generation Lead Time**: 58 minutes before alarm (for freshest daily content)

## 🚀 Scaling Phases

### **Phase 1: Immediate Scaling (No Code Changes)**
**Timeline**: Week 1
**Improvement**: 125x capacity increase

#### **1.1 Optimize Cron Frequency**
- **Current**: Every 2 minutes
- **Target**: Every 1 minute
- **Impact**: 60 alarms/hour (2x improvement)

#### **1.2 Leverage Unlimited Concurrent Execution**
- **Current**: 1 function every 2 minutes
- **Target**: 1 function every 1 minute + unlimited concurrent processing
- **Result**: 3,750 alarms/hour (125x improvement)

#### **Implementation**
```json
{
  "audio_generation": {
    "schedule": "*/1 * * * *",
    "function": "generate-alarm-audio",
    "description": "Process audio generation queue every 1 minute"
  }
}
```

### **Phase 2: Smart Cron Architecture**
**Timeline**: Week 2-3
**Improvement**: Intelligent resource allocation

#### **2.1 Multiple Cron Jobs for Different Priorities**
```json
{
  "urgent_alarms": {
    "schedule": "*/30 * * * *",
    "function": "generate-alarm-audio",
    "priority": "high"
  },
  "standard_alarms": {
    "schedule": "*/2 * * * *",
    "function": "generate-alarm-audio", 
    "priority": "normal"
  },
  "batch_processing": {
    "schedule": "*/5 * * * *",
    "function": "generate-alarm-audio",
    "priority": "batch"
  }
}
```

#### **2.2 Time-Based Cron Optimization**
```bash
# Peak hours (6-8 AM) - Every 30 seconds
"0,30 6-8 * * *"

# Normal hours - Every 2 minutes  
"*/2 0-5,9-23 * * *"

# Off-peak hours (midnight-6 AM) - Every 5 minutes
"*/5 0-5 * * *"
```

### **Phase 3: Intelligent Queue Management**
**Timeline**: Week 2-3
**Improvement**: Priority-based processing

#### **3.1 Priority-Based Queue Processing**
```sql
-- Add priority column to audio_generation_queue
ALTER TABLE audio_generation_queue ADD COLUMN priority INTEGER DEFAULT 5;

-- Update trigger to set priority based on time
CREATE OR REPLACE FUNCTION manage_alarm_audio_queue()
RETURNS TRIGGER AS $$
DECLARE
    time_until_alarm INTERVAL;
    priority_val INTEGER;
BEGIN
    time_until_alarm := NEW.alarm_time_local - CURRENT_TIME;
    
    -- Set priority based on urgency
    IF time_until_alarm < INTERVAL '58 minutes' THEN
        priority_val := 1; -- Critical
    ELSIF time_until_alarm < INTERVAL '1 hour' THEN
        priority_val := 3; -- High
    ELSE
        priority_val := 5; -- Normal
    END IF;
    
    INSERT INTO audio_generation_queue (alarm_id, user_id, scheduled_for, priority)
    VALUES (NEW.id, NEW.user_id, (CURRENT_DATE + NEW.alarm_time_local) - INTERVAL '58 minutes', priority_val);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

#### **3.2 Smart Queue Processing Function**
```typescript
// Process high-priority items first
async function processQueueWithPriority() {
  // 1. Process critical alarms (priority 1) - every 30 seconds
  await processPriorityQueue(1, 30);
  
  // 2. Process high-priority alarms (priority 3) - every 2 minutes
  await processPriorityQueue(3, 120);
  
  // 3. Process normal alarms (priority 5) - every 5 minutes
  await processPriorityQueue(5, 300);
}
```

### **Phase 4: Batch Processing Architecture**
**Timeline**: Month 2
**Improvement**: 3-5x efficiency increase

#### **4.1 Multi-Alarm Processing**
```typescript
// Process multiple alarms per invocation
async function processBatchAlarms() {
  const batchSize = 5; // Process 5 alarms per function call
  
  const alarms = await getPendingAlarms(batchSize);
  
  // Process all alarms in parallel within the function
  const results = await Promise.all(
    alarms.map(alarm => generateAlarmAudio(alarm))
  );
  
  return results;
}
```

#### **4.2 Adaptive Batch Sizing**
```typescript
// Dynamically adjust batch size based on queue load
async function getOptimalBatchSize() {
  const queueLength = await getQueueLength();
  const currentTime = new Date().getHours();
  
  if (queueLength > 1000) return 10; // Large batches for high load
  if (currentTime >= 6 && currentTime <= 8) return 3; // Smaller batches during peak
  return 5; // Default batch size
}
```

### **Phase 5: Advanced Cron Strategies**
**Timeline**: Month 2
**Improvement**: Load-based optimization

#### **5.1 Load-Based Cron Scheduling**
```bash
# Dynamic cron based on queue size
# If queue > 100: every 30 seconds
# If queue > 50: every 1 minute  
# If queue < 10: every 5 minutes
```

#### **5.2 Geographic Time Zone Optimization**
```sql
-- Process alarms based on user time zones
-- Group by time zone to batch similar wake-up times
SELECT timezone_at_creation, COUNT(*) 
FROM alarms 
WHERE active = true 
GROUP BY timezone_at_creation 
ORDER BY COUNT(*) DESC;
```

### **Phase 6: Monitoring & Auto-Scaling**
**Timeline**: Month 3
**Improvement**: Self-optimizing system

#### **6.1 Real-Time Queue Monitoring**
```typescript
// Monitor queue health and adjust processing
async function monitorAndScale() {
  const queueStats = await getQueueStats();
  
  if (queueStats.pending > 1000) {
    // Trigger emergency processing
    await triggerEmergencyProcessing();
  }
  
  if (queueStats.avgProcessingTime > 300) {
    // Reduce batch size
    await adjustBatchSize('decrease');
  }
}
```

#### **6.2 Predictive Scaling**
```typescript
// Predict load based on historical data
async function predictLoad() {
  const historicalData = await getHistoricalLoad();
  const predictedLoad = calculatePredictedLoad(historicalData);
  
  if (predictedLoad > threshold) {
    // Pre-scale processing
    await preScaleProcessing();
  }
}
```

## 📈 Expected Capacity Improvements

| Phase | Alarms/Hour | Alarms/Day | Improvement | Timeline |
|-------|-------------|------------|-------------|----------|
| **Current** | 30 | 720 | Baseline | - |
| **Phase 1** | 3,750 | 90,000 | 125x | Week 1 |
| **Phase 2** | 4,500 | 108,000 | 150x | Week 2-3 |
| **Phase 3** | 5,000 | 120,000 | 167x | Week 2-3 |
| **Phase 4** | 7,500 | 180,000 | 250x | Month 2 |
| **Phase 5** | 8,000 | 192,000 | 267x | Month 2 |
| **Phase 6** | 10,000 | 240,000 | 333x | Month 3 |

## 🎯 Implementation Strategy

### **Week 1: Phase 1**
- [ ] Deploy 1-minute cron
- [ ] Monitor performance
- [ ] Verify 3,750 alarms/hour capacity
- [ ] Document results

### **Week 2-3: Phase 2-3**
- [ ] Implement priority queue
- [ ] Add time-based cron optimization
- [ ] Deploy smart queue processing
- [ ] Test priority-based processing

### **Month 2: Phase 4-5**
- [ ] Implement batch processing
- [ ] Add adaptive batch sizing
- [ ] Deploy load-based scheduling
- [ ] Optimize for peak hours

### **Month 3: Phase 6**
- [ ] Add monitoring and auto-scaling
- [ ] Implement predictive scaling
- [ ] Optimize based on real usage data
- [ ] Document final performance

## 🚨 Risk Mitigation

### **Technical Risks**
- **Function timeout**: Monitor execution times, optimize processing
- **Queue overflow**: Implement emergency processing triggers
- **API rate limits**: Monitor OpenAI usage, implement backoff strategies

### **Operational Risks**
- **Cost overruns**: Monitor Supabase usage, implement cost controls
- **Performance degradation**: Real-time monitoring, automatic scaling
- **User experience**: Maintain audio quality, minimize processing delays

## 📊 Success Metrics

### **Performance Metrics**
- Queue processing time < 5 minutes
- Audio generation success rate > 95%
- Function execution time < 4 minutes
- Error rate < 2%

### **Capacity Metrics**
- Support 10,000+ concurrent users
- Process 10,000+ alarms/hour
- Handle peak morning hours (6-8 AM)
- Maintain 99.9% uptime

### **Cost Metrics**
- Supabase usage < 80% of limits
- OpenAI API costs within budget
- Storage costs optimized
- Processing efficiency > 80%

## 🔮 Future Considerations

### **Architecture Evolution**
- Microservices migration
- CDN integration
- Edge computing optimization
- Machine learning for content optimization

### **Platform Scaling**
- Multi-region deployment
- Load balancing optimization
- Database sharding
- Caching strategies

---

**Last Updated**: June 2025
**Next Review**: After Phase 1 implementation 

**Queue Processing**: Audio is generated 58 minutes before the scheduled alarm time 