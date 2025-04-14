import 'package:flutter/material.dart';
import 'package:unloque/pages/category_details_page.dart';
import 'package:unloque/data/available_applications_data.dart'; // Updated import

class Category {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  Category({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class CategoriesSection extends StatefulWidget {
  final Function(BuildContext, Widget)? onNavigate;

  const CategoriesSection({
    Key? key,
    this.onNavigate,
  }) : super(key: key);

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  bool _isLoading = false;

  final List<Category> categories = [
    Category(
      name: 'Educational',
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
              isLoading: _isLoading,
              onTap: () async {
                // Set loading state
                setState(() {
                  _isLoading = true;
                });

                // Clear cache to load fresh data
                AvailableApplicationsData.clearCache();

                // Navigate using the callback if provided, otherwise use direct navigation
                if (widget.onNavigate != null) {
                  widget.onNavigate!(
                      context,
                      CategoryDetailsPage(
                        categoryName: categories[index].name,
                        categoryColor: categories[index].color,
                      ));
                } else {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryDetailsPage(
                        categoryName: categories[index].name,
                        categoryColor: categories[index].color,
                      ),
                    ),
                  );

                  // If we got a refresh signal, refresh parent
                  if (result == true) {
                    // Handle refresh if needed
                  }
                }

                // Reset loading state
                setState(() {
                  _isLoading = false;
                });
              },
            );
          },
        ),
      ],
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;
  final bool isLoading;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
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
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            color: category.color,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          category.icon,
                          color: category.color,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 12),
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
