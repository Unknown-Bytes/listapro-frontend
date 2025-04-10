import { Suspense } from 'react';
import Home from './Home'; // Ajuste o caminho se necessário
import Loading from '@/components/Loading'; // Componente de loading que você já tem

export default function Page() {
  return (
    <Suspense fallback={<Loading />}>
      <Home />
    </Suspense>
  );
}