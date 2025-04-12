import 'package:flutter/material.dart';
import '../pages/category_details_page.dart';

class Category {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const Category({
    // Make the Category constructor const
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class CategoriesSection extends StatelessWidget {
  final Function(BuildContext, Widget)? onNavigate;

  // Remove const from here
  CategoriesSection({Key? key, this.onNavigate}) : super(key: key);

  // Define categories as a final field
  final List<Category> categories = [
    Category(
      name: 'Education',
      description: 'Access Education Support',
      icon: Icons.school_outlined,
      color: Colors.blue[300]!,
    ),
    Category(
      name: 'Social',
      description: 'Empowering Communities',
      icon: Icons.people_outline,
      color: Colors.green[300]!,
    ),
    Category(
      name: 'Healthcare',
      description: 'Health & Wellness',
      icon: Icons.local_hospital_outlined,
      color: Colors.red[300]!,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.grey[800],
            ),
          ),
        ),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return CategoryCard(
              category: categories[index],
              onNavigate: onNavigate,
            );
          },
        ),
      ],
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;
  final Function(BuildContext, Widget)? onNavigate;

  const CategoryCard({
    super.key,
    required this.category,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4), // reduced vertical padding
      child: Material(
        color: Colors.white,
        elevation: 2, // Add elevation to Material
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            final categoryPage = CategoryDetailsPage(
              categoryName: category.name,
              categoryColor: category.color,
            );

            // Use the callback if provided, otherwise use normal navigation
            if (onNavigate != null) {
              onNavigate!(context, categoryPage);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => categoryPage),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12), // reduced from 16 to 12
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5), // reduced from 12 to 8
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(8), // reduced from 12 to 8
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 30, // reduced from 24 to 20
                  ),
                ),
                const SizedBox(width: 12), // reduced from 16 to 12
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        category.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    color: Colors.grey[200],
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
