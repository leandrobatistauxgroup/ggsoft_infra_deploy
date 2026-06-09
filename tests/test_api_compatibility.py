"""
Testes de compatibilidade de APIs
Verifica se APIs seguem contratos esperados
"""
import pytest
import asyncio
import aiohttp
import json


class TestAPICompatibility:
    """Testa compatibilidade de APIs entre serviços"""
    
    WALLET_AUTH_URL = 'http://python-app-wallet-auth:8888'
    HISTORY_URL = 'http://ggsoft_history:8890'
    RGS_URL = 'http://rgs-fruit:43317'
    
    @pytest.mark.asyncio
    async def test_wallet_auth_credit_endpoint(self):
        """Wallet-Auth /credit deve aceitar POST e retornar JSON"""
        url = f"{self.WALLET_AUTH_URL}/credit"
        payload = {"token": "invalid", "type": "credit"}
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload) as resp:
                assert resp.content_type == 'application/json', \
                    f"Resposta não é JSON: {resp.content_type}"
                data = await resp.json()
                assert 'status' in data, f"Resposta sem campo 'status': {data}"
    
    @pytest.mark.asyncio
    async def test_wallet_auth_open_endpoint(self):
        """Wallet-Auth /open deve aceitar POST com game e location"""
        url = f"{self.WALLET_AUTH_URL}/open"
        payload = {
            "token": "invalid",
            "game": "fruits",
            "location": "GGSOFT"
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload) as resp:
                assert resp.status in [200, 400, 401], \
                    f"Resposta inesperada: {resp.status}"
                data = await resp.json()
                assert 'status' in data, f"Resposta sem 'status': {data}"
    
    @pytest.mark.asyncio
    async def test_history_matches_accepts_post(self):
        """History /matches deve aceitar POST"""
        url = f"{self.HISTORY_URL}/matches"
        payload = {
            "user_id": "test",
            "game": "fruits",
            "limit": 10,
            "offset": 0
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload) as resp:
                # Pode retornar 200 (sucesso) ou 401 (auth) ou 500 (erro)
                # Mas NÃO deve retornar 405 (method not allowed)
                assert resp.status != 405, \
                    "History retorna 405 - espera POST mas recebeu algo errado"
    
    @pytest.mark.asyncio
    async def test_rgs_open_accepts_post(self):
        """RGS /open deve aceitar POST com token e game"""
        url = f"{self.RGS_URL}/open"
        payload = {
            "token": "test",
            "game": "fruits"
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload) as resp:
                assert resp.content_type == 'application/json', \
                    f"RGS não retorna JSON: {resp.content_type}"
                data = await resp.json()
                assert 'status' in data, f"RGS resposta sem 'status': {data}"
    
    @pytest.mark.asyncio
    async def test_rgs_ping_endpoint(self):
        """RGS /ping deve responder"""
        url = f"{self.RGS_URL}/ping"
        payload = {"token": "test"}
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload) as resp:
                assert resp.status == 200, f"RGS ping falhou: {resp.status}"
    
    @pytest.mark.asyncio
    async def test_nginx_serves_game_files(self):
        """Nginx deve servir arquivos de jogos em /games/8/"""
        url = "http://ggsoft_nginx:80/games/8/"
        
        async with aiohttp.ClientSession() as session:
            async with session.get(url) as resp:
                # Pode retornar 200 (index.html) ou 403 (directory listing)
                # Mas NÃO deve retornar 404 (não encontrado)
                assert resp.status != 404, \
                    "Nginx não encontrou arquivos do jogo fruits em /games/8/"
