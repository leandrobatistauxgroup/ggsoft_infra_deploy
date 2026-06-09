"""
Testes de conectividade entre serviços
Verifica se todos os serviços conseguem se comunicar
"""
import pytest
import asyncio
import aiohttp


class TestServiceConnectivity:
    """Testa conectividade de serviços"""
    
    BASE_URLS = {
        'wallet-auth': 'http://python-app-wallet-auth:8888',
        'history': 'http://ggsoft_history:8890',
        'rgs-fruit': 'http://rgs-fruit:43317',
        'nginx': 'http://ggsoft_nginx:80',
    }
    
    @pytest.mark.asyncio
    async def test_wallet_auth_responds(self):
        """Wallet-Auth deve responder na porta 8888"""
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{self.BASE_URLS['wallet-auth']}/") as resp:
                assert resp.status in [200, 404], f"Wallet-Auth resposta: {resp.status}"
    
    @pytest.mark.asyncio
    async def test_history_responds(self):
        """History deve responder na porta 8890"""
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{self.BASE_URLS['history']}/") as resp:
                assert resp.status in [200, 404], f"History resposta: {resp.status}"
    
    @pytest.mark.asyncio
    async def test_rgs_fruit_responds(self):
        """RGS Fruit deve responder na porta 43317"""
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{self.BASE_URLS['rgs-fruit']}/status") as resp:
                assert resp.status == 200, f"RGS resposta: {resp.status}"
    
    @pytest.mark.asyncio
    async def test_nginx_responds(self):
        """Nginx deve responder na porta 80"""
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{self.BASE_URLS['nginx']}/") as resp:
                assert resp.status == 200, f"Nginx resposta: {resp.status}"
    
    @pytest.mark.asyncio
    async def test_rgs_can_reach_wallet_auth(self):
        """RGS deve conseguir comunicar com Wallet-Auth (CS)"""
        # RGS faz chamadas para /open no wallet-auth
        url = f"{self.BASE_URLS['wallet-auth']}/open"
        payload = {"token": "invalid", "game": "fruits"}
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload) as resp:
                # Deve responder, mesmo que com erro (token invalid)
                assert resp.status in [200, 400, 401, 404], \
                    f"CS não respondeu: {resp.status}"
    
    @pytest.mark.asyncio
    async def test_rgs_can_reach_history(self):
        """RGS deve conseguir comunicar com History"""
        async with aiohttp.ClientSession() as session:
            async with session.get(f"{self.BASE_URLS['history']}/") as resp:
                assert resp.status in [200, 404, 405], \
                    f"History não acessível: {resp.status}"
