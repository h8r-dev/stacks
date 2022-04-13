/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  exportPathMap: function () {
    return {
      '/': { page: '/' }
    }
  },
  images: {
    loader: 'akamai',
    path: '',
  },
}

module.exports = nextConfig