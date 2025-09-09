import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:receitas_do_guaxininho/domain/entities/recipe.dart';

void main() {
  group('Testes do Modelo Recipe', () {

    // Teste para o factory constructor 'fromMap' com o formato de dados atual.
    test('Deve criar uma Recipe a partir de um Map (formato atual)', () {
      // 1. Arrange: Prepara os dados de entrada como viriam do banco.
      // 'ingredients' e 'steps' são strings JSON.
      final Map<String, dynamic> map = {
        'id': 101,
        'name': 'Bolo de Fubá com Goiabada',
        'description': 'Um bolo fofinho e delicioso para o café da tarde.',
        'owner': 'user123',
        'ingredients': jsonEncode({
          'Massa': ['Fubá', 'Ovos', 'Leite', 'Açúcar'],
          'Cobertura': ['Goiabada', 'Água']
        }),
        'steps': jsonEncode([
          'Bata os ingredientes da massa no liquidificador.',
          'Despeje em uma forma untada.',
          'Adicione pedaços de goiabada.',
          'Asse em forno médio.'
        ]),
        'category': 'Bolos',
        'timeMinutes': 50,
        'servings': 8,
        'isFavorite': 1, // 'isFavorite' vem como 0 ou 1 do banco
        'imagePath': '/path/to/image.jpg',
      };

      // 2. Act: Executa a função que está sendo testada.
      final recipe = Recipe.fromMap(map);

      // 3. Assert: Verifica se o resultado é o esperado.
      expect(recipe, isA<Recipe>());
      expect(recipe.id, 101);
      expect(recipe.name, 'Bolo de Fubá com Goiabada');
      expect(recipe.owner, 'user123');
      expect(recipe.category, 'Bolos');
      expect(recipe.timeMinutes, 50);
      expect(recipe.servings, 8);
      expect(recipe.isFavorite, isTrue);
      expect(recipe.imagePath, '/path/to/image.jpg');

      // Verifica a estrutura dos ingredientes
      expect(recipe.ingredients, isA<Map<String, List<String>>>());
      expect(recipe.ingredients.containsKey('Massa'), isTrue);
      expect(recipe.ingredients['Massa']?.length, 4);
      expect(recipe.ingredients['Cobertura']?.first, 'Goiabada');

      // Verifica a estrutura dos passos
      expect(recipe.steps, isA<List<String>>());
      expect(recipe.steps.length, 4);
      expect(recipe.steps.first, 'Bata os ingredientes da massa no liquidificador.');
    });

    // Teste para o método 'toMap', que converte o objeto para um Map.
    test('Deve converter uma Recipe para um Map', () {
      // 1. Arrange: Cria uma instância do objeto Recipe.
      final recipe = Recipe(
        id: 102,
        name: 'Moqueca de Peixe',
        description: 'Receita tradicional da culinária baiana.',
        owner: 'user456',
        ingredients: {
          'Moqueca': ['Postas de peixe', 'Leite de coco', 'Azeite de dendê'],
        },
        steps: ['Refogue os temperos', 'Adicione o peixe e o leite de coco'],
        category: 'Frutos do Mar',
        timeMinutes: 40,
        servings: 4,
        isFavorite: false,
      );

      // 2. Act: Chama o método de conversão.
      final map = recipe.toMap();

      // 3. Assert: Verifica se o Map gerado contém os dados corretos.
      expect(map, isA<Map<String, dynamic>>());
      expect(map['name'], 'Moqueca de Peixe');
      expect(map['owner'], 'user456');
      expect(map['timeMinutes'], 40);

      // Verifica se 'ingredients' e 'steps' foram convertidos para strings JSON.
      expect(map['ingredients'], isA<String>());
      expect(map['steps'], isA<String>());

      // Opcional: decodifica para garantir que o conteúdo está correto.
      final decodedIngredients = jsonDecode(map['ingredients']);
      expect(decodedIngredients['Moqueca'].length, 3);
    });

    // Teste para o método 'copyWith'
    test('Deve criar uma cópia da Recipe com valores atualizados usando copyWith', () {
      // 1. Arrange: Cria uma receita original.
      final originalRecipe = Recipe(
        id: 103,
        name: 'Pizza Original',
        description: 'Massa fina',
        owner: 'user789',
        ingredients: {'Massa': ['Farinha', 'Água']},
        steps: ['Misturar', 'Assar'],
        category: 'Massas',
        timeMinutes: 90,
        servings: 6,
        isFavorite: false,
        imagePath: '/path/original.jpg',
      );

      // 2. Act: Usa o copyWith para criar uma nova instância com dados modificados.
      final updatedRecipe = originalRecipe.copyWith(
        name: 'Pizza Nova e Melhorada',
        isFavorite: true,
        servings: 8,
      );

      final recipeNoImage = originalRecipe.copyWith(clearImagePath: true);


      // 3. Assert: Verifica se os campos foram atualizados corretamente
      // e se os campos não modificados permaneceram os mesmos.
      expect(updatedRecipe.id, originalRecipe.id); // não mudou
      expect(updatedRecipe.owner, originalRecipe.owner); // não mudou
      expect(updatedRecipe.name, 'Pizza Nova e Melhorada'); // mudou
      expect(updatedRecipe.isFavorite, isTrue); // mudou
      expect(updatedRecipe.servings, 8); // mudou
      expect(updatedRecipe.imagePath, originalRecipe.imagePath); // não mudou

      // Testa a remoção da imagem
      expect(recipeNoImage.imagePath, isNull);
    });

    // Teste para o 'fromMap' com um formato antigo de ingredientes (List<String>)
    test('Deve criar uma Recipe a partir de um Map (formato antigo de ingredientes)', () {
      // 1. Arrange: Prepara um map com 'ingredients' como uma lista JSON.
      final Map<String, dynamic> map = {
        'id': 104,
        'name': 'Vitamina de Banana',
        'description': 'Simples e rápida.',
        'owner': 'legacy_user',
        'ingredients': jsonEncode(['Banana', 'Leite', 'Aveia']), // Formato antigo
        'steps': jsonEncode(['Bater tudo.']),
        'category': 'Bebidas',
        'timeMinutes': 5,
        'servings': 1,
        'isFavorite': 0,
      };

      // 2. Act:
      final recipe = Recipe.fromMap(map);

      // 3. Assert: Verifica se os ingredientes foram agrupados sob a chave padrão.
      expect(recipe.ingredients.containsKey('Ingredientes'), isTrue);
      expect(recipe.ingredients['Ingredientes']?.length, 3);
      expect(recipe.ingredients['Ingredientes']?.first, 'Banana');

    });
  });
}

