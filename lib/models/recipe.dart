class RecipeIngredient {
  final String ing; // StockItem ID
  final double qty; // quantity per portion in StockItem's unit

  const RecipeIngredient({required this.ing, required this.qty});
}

class Recipe {
  final String menuItemId;
  final List<RecipeIngredient> ingredients;

  const Recipe({required this.menuItemId, required this.ingredients});
}
