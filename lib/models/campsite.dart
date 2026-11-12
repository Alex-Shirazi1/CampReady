import 'package:equatable/equatable.dart';

class Campsite extends Equatable {
  const Campsite({
    required this.id,
    required this.name,
    required this.area,
    required this.image,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.pricePerNight,
    required this.siteType,
    required this.maxGuests,
    required this.petFriendly,
    required this.conditionsKnown,
    required this.fireRule,
    required this.fireDetail,
    required this.closures,
  });

  final String id;
  final String name;
  final String area;
  final String image;
  final String description;
  final double latitude;
  final double longitude;
  final int pricePerNight;
  final String siteType;
  final int maxGuests;
  final bool petFriendly;

  /// False when the park feed for fire rules and closures is unavailable.
  final bool conditionsKnown;
  final String fireRule;
  final String fireDetail;
  final String closures;

  String get price => '\$$pricePerNight / night';

  String get summary => [
    siteType == 'Tent' ? 'Tent sites' : 'RV-friendly spaces',
    'Up to $maxGuests guests',
    if (petFriendly) 'Pets welcome',
  ].join(' · ');

  @override
  List<Object?> get props => [id];
}

/// Filters on the Explore screen. Budget is the max nightly price, or null.
class CampsiteFilters extends Equatable {
  const CampsiteFilters({
    this.siteType = 'Tent',
    this.travelers = 2,
    this.maxPrice,
    this.petsRequired = true,
  });

  final String siteType;
  final int travelers;
  final int? maxPrice;
  final bool petsRequired;

  bool matches(Campsite site) =>
      site.siteType == siteType &&
      site.maxGuests >= travelers &&
      (maxPrice == null || site.pricePerNight < maxPrice!) &&
      (!petsRequired || site.petFriendly);

  CampsiteFilters copyWith({
    String? siteType,
    int? travelers,
    int? Function()? maxPrice,
    bool? petsRequired,
  }) => CampsiteFilters(
    siteType: siteType ?? this.siteType,
    travelers: travelers ?? this.travelers,
    maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
    petsRequired: petsRequired ?? this.petsRequired,
  );

  @override
  List<Object?> get props => [siteType, travelers, maxPrice, petsRequired];
}
