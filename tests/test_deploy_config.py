"""
Testes de configuração do deploy
Verifica se todas as configurações estão corretas
"""
import os
import pytest


class TestDeployConfiguration:
    """Testa configurações de deploy"""
    
    def test_rgs_game_name_is_fruits(self):
        """RGS deve ter GAME_NAME=fruits (com 's')"""
        game_name = os.environ.get('RGS_GAME_NAME', '')
        assert game_name == 'fruits', \
            f"GAME_NAME deve ser 'fruits', encontrado: '{game_name}'"
    
    def test_rgs_game_code_is_8(self):
        """RGS deve ter GAME_CODE=8 (ID do fruits)"""
        game_code = os.environ.get('RGS_GAME_CODE', '')
        assert game_code == '8', \
            f"GAME_CODE deve ser '8', encontrado: '{game_code}'"
    
    def test_rgs_port_is_43317(self):
        """RGS deve usar porta 43317"""
        port = os.environ.get('RGS_PORT', '')
        assert port == '43317', \
            f"PORT deve ser '43317', encontrado: '{port}'"
    
    def test_history_api_secret_configured(self):
        """History deve ter API_SECRET_KEY configurado"""
        secret = os.environ.get('HISTORY_API_SECRET', '')
        assert len(secret) >= 24, \
            f"API_SECRET_KEY deve ter >= 24 caracteres, tem: {len(secret)}"
    
    def test_wallet_auth_mysql_connection_string(self):
        """Wallet-Auth deve ter conexão MySQL configurada"""
        host = os.environ.get('WALLET_MYSQL_HOST', '')
        assert host != '', \
            "WALLET_MYSQL_HOST não configurado"
    
    def test_all_required_env_vars_present(self):
        """Todas as variáveis de ambiente necessárias devem estar presentes"""
        required = [
            'RGS_GAME_NAME',
            'RGS_GAME_CODE',
            'RGS_PORT',
            'HISTORY_API_SECRET',
            'WALLET_MYSQL_HOST',
        ]
        
        missing = [var for var in required if not os.environ.get(var)]
        assert len(missing) == 0, \
            f"Variáveis de ambiente ausentes: {missing}"
