const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

async function decodeBarcode(buffer) {
  const tempPath = path.join(os.tmpdir(), `barcode_${Date.now()}.png`);
  fs.writeFileSync(tempPath, buffer);

  return new Promise((resolve, reject) => {
    const proc = spawn('zbarimg', ['--raw', tempPath]);

    let result = '';
    proc.stdout.on('data', (data) => {
      result += data.toString();
    });

    proc.stderr.on('data', (data) => {
      console.error("zbarimg error:", data.toString());
    });

    proc.on('close', (code) => {
      fs.unlinkSync(tempPath); // Clean up
      if (code === 0 && result.trim()) {
        resolve(result.trim());
      } else {
        resolve(null);
      }
    });
  });
}

module.exports = { decodeBarcode };
