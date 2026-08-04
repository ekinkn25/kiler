"""Tum ORM modelleri.

DIKKAT: Yeni bir model yazdiginda MUTLAKA buraya ekle.
Alembic ve create_all yalnizca import edilmis modelleri gorur.
"""
from app.models.catalog import (
    Category,
    Ingredient,
    IngredientAlias,
    Product,
    UnmatchedIngredient,
)
from app.models.chat import ChatConversation, ChatMessage, LlmCache
from app.models.nutrition import MealLog, WeightLog
from app.models.pantry import PantryEvent, PantryItem, ShoppingListItem
from app.models.recipe import RecipeFavorite, RecipeFeedback, UserTasteWeight
from app.models.user import (
    Allergen,
    DietTag,
    User,
    UserProfile,
    user_allergens,
    user_diet_tags,
)

__all__ = [
    # A. Kullanici
    "User", "UserProfile", "DietTag", "Allergen",
    "user_diet_tags", "user_allergens",
    # B. Sozluk / katalog
    "Category", "Ingredient", "IngredientAlias", "UnmatchedIngredient", "Product",
    # C. Kiler
    "PantryItem", "PantryEvent", "ShoppingListItem",
    # D. Kalori
    "MealLog", "WeightLog",
    # E. Tarif
    "RecipeFeedback", "RecipeFavorite", "UserTasteWeight",
    # F. AI
    "ChatConversation", "ChatMessage", "LlmCache",
]