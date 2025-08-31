# LoveConf

Um aplicativo Flutter moderno e elegante para conectar corações através de PINs seguros.

## 🎨 Design

- **Tema**: Escuro com gradientes elegantes
- **Cores principais**: #191919 e #000000
- **Estilo**: Material Design 3 com customizações personalizadas
- **Interface**: Moderna e responsiva

## 🏗️ Estrutura do Projeto

```
lib/
├── main.dart                    # Ponto de entrada da aplicação
├── theme/
│   └── app_theme.dart          # Tema personalizado e cores
├── models/
│   └── connection.dart          # Modelo de dados para conexões
├── services/
│   ├── connection_service.dart  # Serviço para gerenciar conexões
│   └── permission_service.dart # Serviço para permissões
├── screens/
│   ├── home_screen.dart        # Tela inicial
│   ├── admin_screen.dart       # Tela administrativa
│   └── client_screen.dart      # Tela do cliente
├── widgets/
│   ├── gradient_button.dart    # Botão personalizado com gradiente
│   ├── pin_dialog.dart         # Diálogo de PIN
│   └── connection_card.dart    # Card de conexão
└── utils/
    ├── app_constants.dart      # Constantes da aplicação
    └── firebase_config.dart    # Configuração do Firebase
```

## 🚀 Funcionalidades

### 🔐 **Sistema de Conexões**
- **Admin**: Cria conexões com PINs aleatórios de 4 dígitos
- **Client**: Conecta-se usando PINs fornecidos
- **Tempo real**: Sincronização automática via Firestore
- **Status**: Aguardando, Conectado, Cancelado

### 📱 **Tela Inicial (Home)**
- Design moderno com gradiente escuro
- Logo animado com ícone de coração
- Dois botões principais: Admin e Client
- Navegação fluida entre telas

### 👨‍💼 **Tela Admin**
- **Botão "Criar Conexão"**: Gera PIN aleatório
- **Diálogo de PIN**: Exibe código com botão copiar
- **Lista de conexões**: Mostra todas as conexões criadas
- **Gerenciamento**: Cancelar conexões pendentes
- **Datas**: Exibe quando cada conexão foi criada

### 👤 **Tela Client**
- **Botão "Ativar Permissões"**: Solicita permissões de notificação
- **Campo PIN**: Input para código de 4 dígitos
- **Botão "Conectar"**: Estabelece conexão com admin
- **Status**: Mostra estado das permissões
- **Validação**: Verifica PIN antes de conectar

## 🔥 **Firebase Integration**

### **Coleções Automáticas**
- `connections/` - Criada automaticamente se não existir
- Estrutura otimizada para consultas em tempo real
- Índices configurados para performance

### **Estrutura de Dados**
```json
{
  "pin": "1234",
  "status": "waiting|connected|cancelled",
  "adminId": "admin_123",
  "clientId": "client_456",
  "createdAt": "timestamp",
  "connectedAt": "timestamp",
  "cancelledAt": "timestamp"
}
```

## 🎯 **Características Técnicas**

- **Flutter**: Versão mais recente
- **Firebase**: Firestore em tempo real
- **Arquitetura**: Limpa e escalável
- **Tema**: Consistente em toda a aplicação
- **Responsividade**: Adaptável a diferentes tamanhos de tela
- **Código**: Seguindo as melhores práticas do Flutter

## 🔧 **Configuração**

1. **Clone o repositório**
2. **Execute `flutter pub get`**
3. **Configure o Firebase** (google-services.json já está no projeto)
4. **Execute `flutter run`**

## 📱 **Como Usar**

### **Para Admins:**
1. Acesse a tela Admin
2. Clique em "Criar Conexão"
3. Copie o PIN gerado
4. Compartilhe com o cliente
5. Monitore o status da conexão

### **Para Clientes:**
1. Acesse a tela Client
2. Ative as permissões de notificação
3. Digite o PIN fornecido pelo admin
4. Clique em "Conectar"
5. Aguarde confirmação da conexão

## 🚧 **Status do Projeto**

- ✅ **Estrutura base implementada**
- ✅ **Tema personalizado criado**
- ✅ **Sistema de conexões completo**
- ✅ **Firebase integrado e funcionando**
- ✅ **Interface responsiva e moderna**
- ✅ **Navegação entre telas funcionando**
- ✅ **Permissões de notificação implementadas**

## 🔮 **Próximos Passos**

- [ ] Sistema de autenticação de usuários
- [ ] Notificações push em tempo real
- [ ] Histórico de conexões
- [ ] Configurações personalizáveis
- [ ] Backup e sincronização offline

## 🤝 **Contribuição**

Este projeto está em desenvolvimento ativo. Contribuições são bem-vindas!

## 📄 **Licença**

Este projeto é privado e proprietário.

---

**Desenvolvido com ❤️ usando Flutter e Firebase**
