def estimate_calories(protein, carbs, fat):
    """Estimate calories from macronutrients using the Atwater system."""
    return round((protein * 4) + (carbs * 4) + (fat * 9), 2)
