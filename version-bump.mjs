import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// ESM'de __dirname'i elde etmek için
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Package.json dosyasının yolunu belirle
const packageJsonPath = path.join(__dirname, 'package.json');

try {
  // Package.json dosyasını oku
  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
  
  // Mevcut versiyonu al
  const currentVersion = packageJson.version;
  console.log(`Current version: ${currentVersion}`);
  
  // Versiyon parçalarını ayır (major.minor.patch)
  const versionParts = currentVersion.split('.');
  
  // Patch numarasını bir artır
  versionParts[2] = (parseInt(versionParts[2], 10) + 1).toString();
  
  // Yeni versiyonu oluştur
  const newVersion = versionParts.join('.');
  console.log(`New version: ${newVersion}`);
  
  // Yeni versiyonu package.json'a yaz
  packageJson.version = newVersion;
  
  // Güncellenmiş package.json dosyasını kaydet (güzel formatla)
  fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2) + '\n');
  
  console.log(`Version successfully updated: ${currentVersion} -> ${newVersion}`);
} catch (error) {
  console.error('Error during version update:', error.message);
  process.exit(1);
}
