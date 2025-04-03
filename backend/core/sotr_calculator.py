from abc import ABC, abstractmethod
import json

class SaturationCalculator(ABC):
    def __init__(self, data_path):
        self.data_path = data_path
        self.load_data()
        
    def load_data(self):
        try:
            with open(self.data_path, 'r') as f:
                data = json.load(f)
                self.metadata = data["metadata"]
                self.matrix = data["data"]
                self.temp_step = self.metadata["temperature_range"]["step"]
                self.sal_step = self.metadata["salinity_range"]["step"]
                self.unit = self.metadata["unit"]
        except FileNotFoundError:
            raise Exception(f"Data file not found at {self.data_path}")
        except json.JSONDecodeError:
            raise Exception("Invalid JSON format in data file")

    def get_o2_saturation(self, temperature, salinity):
        if not (0 <= temperature <= 40 and 0 <= salinity <= 40):
            raise ValueError("Temperature and salinity must be between 0 and 40")
        temp_idx = round(temperature)  # Round temperature to nearest integer
        sal_idx = int(salinity / self.sal_step)
        return self.matrix[temp_idx][sal_idx]

    @abstractmethod
    def calculate_sotr(self, temperature, salinity, *args, **kwargs):
        pass

class ShrimpPondCalculator(SaturationCalculator):
    SOTR_PER_HP = {
        "Generic Paddlewheel": 1.8
    }

    BRAND_NORMALIZATION = {
        "pentair": "Pentair", "beraqua": "Beraqua", "maof madam": "Maof Madam",
        "maofmadam": "Maof Madam", "cosumisa": "Cosumisa", "pioneer": "Pioneer",
        "ecuasino": "Ecuasino", "diva": "Diva", "gps": "GPS", "wangfa": "WangFa",
        "akva": "AKVA", "xylem": "Xylem", "newterra": "Newterra", "tsurumi": "TSURUMI",
        "oxyguard": "OxyGuard", "linn": "LINN", "hunan": "Hunan", "sagar": "Sagar",
        "hcp": "HCP", "yiyuan": "Yiyuan", "generic": "Generic",
        "pentairr": "Pentair", "beraqua1": "Beraqua", "maof-madam": "Maof Madam",
        "cosumissa": "Cosumisa", "pionner": "Pioneer", "ecuacino": "Ecuasino",
        "divva": "Diva", "wang fa": "WangFa", "oxy guard": "OxyGuard", "lin": "LINN",
        "sagr": "Sagar", "hcpp": "HCP", "yiyuan1": "Yiyuan",
    }

    def __init__(self, data_path):
        super().__init__(data_path)
    
    def normalize_brand(self, brand):
        if not brand or brand.strip() == "":
            return "Generic"
        brand_lower = brand.lower().strip()
        return self.BRAND_NORMALIZATION.get(brand_lower, brand)

    def calculate_sotr(self, temperature, salinity, volume, efficiency=0.9):
        saturation = self.get_o2_saturation(temperature, salinity)
        saturation_kg_m3 = saturation * 0.001
        return int(saturation_kg_m3 * volume * efficiency * 100) / 100  # Truncate to 2 decimals

    def calculate_metrics(self, temperature, salinity, hp, volume, t10, t70, kwh_price, aerator_id):
        # Split aerator_id into brand and type
        try:
            brand, aerator_type = aerator_id.split(" ", 1)
        except ValueError:
            brand = aerator_id
            aerator_type = "Unknown"

        normalized_brand = self.normalize_brand(brand)
        normalized_aerator_id = f"{normalized_brand} {aerator_type}"

        power_kw = int(hp * 0.746 * 100) / 100  # Truncate to 2 decimals
        cs = self.get_o2_saturation(temperature, salinity)
        cs20 = self.get_o2_saturation(20, salinity)
        cs20_kg_m3 = cs20 * 0.001

        kla_t = 1.0 / ((t70 - t10) / 60)  # No 1.1 factor, keep t10/t70 as fractions
        kla20 = kla_t * (1.024 ** (20 - temperature))

        sotr = int(kla20 * cs20_kg_m3 * volume * 100) / 100  # Truncate to 2 decimals
        sae = sotr / power_kw if power_kw > 0 else 0
        sae = int(sae * 100) / 100  # Truncate to 2 decimals
        cost_per_kg = kwh_price / sae if sae > 0 else float('inf')
        cost_per_kg = int(cost_per_kg * 100) / 100  # Truncate to 2 decimals

        return {
            "Pond Volume (m³)": volume,
            "Cs (mg/L)": cs,
            "KlaT (h⁻¹)": kla_t,
            "Kla20 (h⁻¹)": kla20,
            "SOTR (kg O₂/h)": sotr,
            "SAE (kg O₂/kWh)": sae,
            "US$/kg O₂": cost_per_kg,
            "Power (kW)": power_kw,
            "Normalized Aerator ID": normalized_aerator_id
        }

    def get_ideal_volume(self, hp):
        if hp == 2:
            return 40
        elif hp == 3:
            return 70
        else:
            return hp * 25

    def get_ideal_hp(self, volume):
        if volume <= 40:
            return 2
        elif volume <= 70:
            return 3
        else:
            return max(2, int(volume / 25))