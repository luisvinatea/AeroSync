from abc import ABC, abstractmethod
import json
import os

class SaturationCalculator(ABC):
    def __init__(self, data_path):
        """Initialize with path to JSON data file"""
        self.data_path = data_path
        self.load_data()
        
    def load_data(self):
        """Load the saturation data from JSON"""
        try:
            with open(self.data_path, 'r') as f:
                data = json.load(f)
                self.metadata = data["metadata"]
                self.matrix = data["data"]
                self.temp_step = self.metadata["temperature_range"]["step"]
                self.sal_step = self.metadata["salinity_range"]["step"]
                self.unit = self.metadata["unit"]  # Read the unit from metadata
        except FileNotFoundError:
            raise Exception(f"Data file not found at {self.data_path}")
        except json.JSONDecodeError:
            raise Exception("Invalid JSON format in data file")

    def get_o2_saturation(self, temperature, salinity):
        """Get O2 saturation value for given temperature and salinity"""
        if not (0 <= temperature <= 40 and 0 <= salinity <= 40):
            raise ValueError("Temperature and salinity must be between 0 and 40")
        temp_idx = int(temperature / self.temp_step)
        sal_idx = int(salinity / self.sal_step)
        return self.matrix[temp_idx][sal_idx]

    @abstractmethod
    def calculate_sotr(self, temperature, salinity, *args, **kwargs):
        """Abstract method to calculate Standard Oxygen Transfer Rate"""
        pass

class ShrimpPondCalculator(SaturationCalculator):
    # Lookup table for SOTR per HP by aerator brand/model/version (placeholder values)
    SOTR_PER_HP = {
        "Generic Paddlewheel": 1.8  # kg O₂/h per HP (default for unknown paddlewheels)
        # Add more specific paddlewheels after experiments, e.g.,
        # "AquaPaddle Model X V1": 1.9,
        # "PaddlePro Model Y V2": 1.7
    }

    def __init__(self, data_path):
        super().__init__(data_path)
    
    def calculate_sotr(self, temperature, salinity, volume, efficiency=0.9):
        """Calculate SOTR for shrimp pond"""
        saturation = self.get_o2_saturation(temperature, salinity)  # In mg/L
        # Convert saturation to kg/m³ for calculation
        saturation_kg_m3 = saturation * 0.001  # mg/L to kg/m³
        return saturation_kg_m3 * volume * efficiency

    def calculate_metrics(self, temperature, salinity, hp, volume, t10, t70, kwh_price, aerator_id, 
                        do_deficit_factor=1.0, water_depth_factor=1.0, placement_factor=1.0):
        """
        Calculate SOTR, SAE, and cost metrics for an aerator based on experimental t10 and t70 values.
        
        Parameters:
        - temperature (float): Water temperature (°C)
        - salinity (float): Salinity (‰)
        - hp (float): Aerator horsepower
        - volume (float): Pond volume (m³)
        - t10 (float): Time to reach 10% saturation (minutes)
        - t70 (float): Time to reach 70% saturation (minutes)
        - kwh_price (float): Electricity cost ($/kWh)
        - aerator_id (str): Identifier for the aerator
        - do_deficit_factor, water_depth_factor, placement_factor: Placeholder adjustment factors (default 1.0)
        
        Returns:
        - dict: Metrics including SOTR, SAE, and cost per kg of oxygen
        """
        # Convert horsepower to kilowatts
        power_kw = hp * 0.746  # 1 hp = 0.746 kW

        # Current oxygen saturation at operating temperature and salinity (mg/L)
        cs = self.get_o2_saturation(temperature, salinity)

        # Oxygen saturation at standard temperature (20°C) and given salinity (mg/L)
        cs20 = self.get_o2_saturation(20, salinity)
        cs20_kg_m3 = cs20 * 0.001  # Convert to kg/m³

        # Calculate oxygen transfer coefficient at current temperature (h⁻¹)
        kla_t = 1.1 / ((t70 - t10) / 60)  # Convert time difference to hours

        # Adjust to standard temperature of 20°C (h⁻¹)
        kla20 = kla_t * (1.024 ** (20 - temperature))

        # Calculate SOTR based on t10 and t70 (kg/h)
        sotr = kla20 * cs20_kg_m3 * volume

        # Calculate Standard Aeration Efficiency (kg O₂/kWh)
        sae = sotr / power_kw if power_kw > 0 else 0

        # Calculate cost per kg of oxygen transferred ($/kg O₂)
        cost_per_kg = kwh_price / sae if sae > 0 else float('inf')

        # Return metrics as a dictionary
        return {
            "Pond Volume (m³)": volume,
            "Cs (mg/L)": cs,
            "KlaT (h⁻¹)": kla_t,
            "Kla20 (h⁻¹)": kla20,
            "SOTR (kg O₂/h)": sotr,
            "SAE (kg O₂/kWh)": sae,
            "US$/kg O₂": cost_per_kg,
            "Power (kW)": power_kw
        }

    def get_ideal_volume(self, hp):
        """Return ideal pond volume based on HP"""
        if hp == 2:
            return 40
        elif hp == 3:
            return 70
        else:
            return hp * 25

    def get_ideal_hp(self, volume):
        """Return ideal HP based on pond volume"""
        if volume <= 40:
            return 2
        elif volume <= 70:
            return 3
        else:
            return max(2, int(volume / 25))