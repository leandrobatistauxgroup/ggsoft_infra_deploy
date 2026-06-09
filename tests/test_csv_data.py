"""
Testes de integridade dos dados CSV
Verifica se os dados estão consistentes entre os arquivos CSV
"""
import csv
import os
import pytest


class TestCSVDataIntegrity:
    """Testa integridade dos dados CSV para deploy"""
    
    BASE_PATH = "/app/wallet-auth-data"  # Path no container de teste
    
    def test_game_csv_has_fruits_with_id_8(self):
        """Game 'fruits' deve ter ID 8 para compatibilidade com banco legado"""
        with open(f"{self.BASE_PATH}/game.csv", 'r') as f:
            reader = csv.DictReader(f)
            games = list(reader)
        
        fruits = [g for g in games if g['name'] == 'fruits']
        assert len(fruits) == 1, f"Deve ter exatamente 1 game 'fruits', encontrados: {len(fruits)}"
        assert fruits[0]['id'] == '8', f"Game 'fruits' deve ter id=8, encontrado: {fruits[0]['id']}"
    
    def test_location_csv_has_ggsoft_with_games_path(self):
        """Location GGSOFT deve ter game_url com /games/"""
        with open(f"{self.BASE_PATH}/location.csv", 'r') as f:
            reader = csv.DictReader(f)
            locations = list(reader)
        
        ggsoft = [l for l in locations if l['name'] == 'GGSOFT']
        assert len(ggsoft) >= 1, "Deve ter location 'GGSOFT'"
        
        for loc in ggsoft:
            assert '/games' in loc['game_url'], \
                f"GGSOFT game_url deve conter '/games', encontrado: {loc['game_url']}"
    
    def test_game_location_csv_fruits_linked_to_ggsoft(self):
        """Fruits (id=8) deve estar associado a GGSOFT (id=1)"""
        with open(f"{self.BASE_PATH}/game_location.csv", 'r') as f:
            reader = csv.DictReader(f)
            game_locs = list(reader)
        
        fruits_ggsoft = [gl for gl in game_locs 
                        if gl['id_game'] == '8' and gl['id_location'] == '1']
        assert len(fruits_ggsoft) >= 1, \
            "Deve ter game_location com fruits(8) -> GGSOFT(1)"
    
    def test_game_location_csv_uses_correct_rgs_port(self):
        """RGS URL deve usar porta 43317 (fruits)"""
        with open(f"{self.BASE_PATH}/game_location.csv", 'r') as f:
            reader = csv.DictReader(f)
            game_locs = list(reader)
        
        for gl in game_locs:
            if gl['id_game'] == '8':  # fruits
                assert '43317' in gl['rgs_url'], \
                    f"Fruits deve usar RGS porta 43317, encontrado: {gl['rgs_url']}"
    
    def test_users_csv_has_test_users_with_is_test(self):
        """Usuários de teste devem ter is_test=1"""
        with open(f"{self.BASE_PATH}/users.csv", 'r') as f:
            reader = csv.DictReader(f)
            users = list(reader)
        
        # Deve ter usuários com is_test=1
        test_users = [u for u in users if u.get('is_test') == '1']
        assert len(test_users) >= 1, "Deve ter pelo menos 1 usuário de teste (is_test=1)"
    
    def test_users_csv_has_production_users(self):
        """Deve ter usuários de produção (is_test=0)"""
        with open(f"{self.BASE_PATH}/users.csv", 'r') as f:
            reader = csv.DictReader(f)
            users = list(reader)
        
        prod_users = [u for u in users if u.get('is_test') == '0']
        assert len(prod_users) >= 1, "Deve ter pelo menos 1 usuário de produção (is_test=0)"
