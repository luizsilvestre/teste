const express = require('express');
const cors = require('cors');
const { Client } = require('whatsapp-web.js');
const qrcode = require('qrcode-terminal');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const client = new Client();

// QR Code para autenticação
client.on('qr', (qr) => {
  console.log('\n📱 Escaneie este QR Code com seu WhatsApp:');
  qrcode.generate(qr, { small: true });
});

// Bot pronto
client.on('ready', () => {
  console.log('✅ WhatsApp Bot conectado!');
});

// Inicializar cliente
client.initialize();

// Rota pra enviar alerta
app.post('/api/alertar-vencimento', (req, res) => {
  const { numero, medicamento, dataVencimento } = req.body;

  if (!numero || !medicamento || !dataVencimento) {
    return res.status(400).json({ erro: 'Dados incompletos' });
  }

  const mensagem = `🚨 *ALERTA DE VENCIMENTO*\n\nMedicamento: ${medicamento}\nVence em: ${dataVencimento}\n\nVerifique o estoque!`;

  // Enviar para WhatsApp
  const numeroFormatado = `55${numero}@c.us`; // Formato Brasil
  
  client
    .sendMessage(numeroFormatado, mensagem)
    .then(() => {
      console.log(`✅ Mensagem enviada para ${numero}`);
      res.json({ sucesso: true, mensagem: 'Alerta enviado!' });
    })
    .catch((err) => {
      console.error('❌ Erro ao enviar:', err);
      res.status(500).json({ erro: 'Falha ao enviar' });
    });
});

// Health check
app.get('/api/status', (req, res) => {
  res.json({ status: 'Servidor rodando!' });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`🚀 Servidor rodando em http://localhost:${PORT}`);
});
