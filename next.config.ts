import type { NextConfig } from "next";

const nextConfig: NextConfig = {

  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: 'http://listapro-backend-service:8080/api/:path*'
      }
    ];
  },
};

export default nextConfig;
