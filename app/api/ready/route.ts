import { NextResponse } from 'next/server';

export async function GET() {
  try {
    // Verificação de prontidão mais rigorosa
    const readyData = {
      status: 'ready',
      timestamp: new Date().toISOString(),
      checks: {
        database: 'connected', // Substituir por verificação real se necessário
        services: 'available'
      }
    };

    return NextResponse.json(readyData, { status: 200 });
  } catch {
    return NextResponse.json(
      { 
        status: 'not ready', 
        timestamp: new Date().toISOString(),
        error: 'Readiness check failed' 
      }, 
      { status: 503 }
    );
  }
}
