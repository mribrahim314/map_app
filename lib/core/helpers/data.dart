class Data {
  static const Map<String, List<String>> lebanonGovernoratesAndDistricts = {
    'Akkar': ['Akkar'],
    'Baalbek-Hermel': ['Baalbek', 'Hermel'],
    'Beirut': [
      // No districts — Beirut is a standalone governorate
      'Beirut',
    ],
    'Beqaa': ['Rashaya', 'Western Beqaa', 'Zahle'],
    'Keserwan-Jbeil': ['Byblos (Jbeil)', 'Keserwan'],
    'Mount Lebanon': ['Aley', 'Baabda', 'Chouf', 'Matn (Metn)'],
    'Nabatieh': ['Bint Jbeil', 'Hasbaya', 'Marjeyoun', 'Nabatieh'],
    'North': [
      'Batroun',
      'Bsharri',
      'Koura',
      'Miniyeh-Danniyeh',
      'Tripoli',
      'Zgharta',
    ],
    'South': ['Jezzine', 'Sidon (Saida)', 'Tyre (Sour)'],
  };

  /// Optional: Get list of governorate names
  static List<String> get governorates =>
      lebanonGovernoratesAndDistricts.keys.toList();

  /// Optional: Get districts of a given governorate
  static List<String> getDistricts(String? governorate) {
    return lebanonGovernoratesAndDistricts[governorate] ?? [];
  }

  static const List<String> Categories = [
    'دراق - Plums',
    'خوخ - Peaches',
    'لوزيات - Almonds',
    'تين - Figs',
    'عنب - Grapes',
    'إكيدنيا - Loquats',
    'حمضيات - Citrus',
    'تفاح - Apples',
    'زيتون - Olives',
    'فستق حلبي - Pistachios',
    'كرز - Cherries',
    'جوز - Walnuts',
    'خرما - Persimmons',
    'أفوكادو - Avocados',
    'سماق - Sumac',
    'خروب - Carob',
    'قشطة - Cherimoya',
    'جوافة - Guava',
    // 'موز - Banana',
    'Others',
  ];
}
