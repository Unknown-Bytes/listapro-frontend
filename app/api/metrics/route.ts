import { NextResponse } from 'next/server';

export const dynamic = 'force-static';

// Simulação de métricas para Prometheus
let requestCount = 0;
const startTime = Date.now();

export async function GET() {
  requestCount++;
  
  const metrics = `
# HELP app_requests_total Total number of requests
# TYPE app_requests_total counter
app_requests_total ${requestCount}

# HELP app_uptime_seconds Application uptime in seconds
# TYPE app_uptime_seconds gauge
app_uptime_seconds ${Math.floor((Date.now() - startTime) / 1000)}

# HELP app_info Application information
# TYPE app_info gauge
app_info{version="1.0.0",environment="${process.env.NODE_ENV || 'development'}"} 1

# HELP nodejs_memory_usage_bytes Memory usage in bytes
# TYPE nodejs_memory_usage_bytes gauge
nodejs_memory_usage_bytes{type="rss"} ${process.memoryUsage().rss}
nodejs_memory_usage_bytes{type="heapTotal"} ${process.memoryUsage().heapTotal}
nodejs_memory_usage_bytes{type="heapUsed"} ${process.memoryUsage().heapUsed}
nodejs_memory_usage_bytes{type="external"} ${process.memoryUsage().external}
`;

  return new NextResponse(metrics, {
    status: 200,
    headers: {
      'Content-Type': 'text/plain; charset=utf-8',
    },
  });
}
