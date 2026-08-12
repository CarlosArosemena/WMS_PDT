import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.mintel.wmsrf',
  appName: 'M-INTEL WMS RF',
  webDir: 'www',
  bundledWebRuntime: false,
  server: {
    androidScheme: 'https'
  },
  android: {
    allowMixedContent: false
  }
};

export default config;
