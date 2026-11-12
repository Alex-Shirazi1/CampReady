import '../models/campsite.dart';
import '../services/services.dart';

const campsiteCatalog = [
  Campsite(
    id: 'redwood-grove',
    name: 'Redwood Grove',
    area: 'Santa Cruz, California',
    image: 'assets/images/a1bf3d0137c87172.png',
    description: 'A quiet clearing beneath the redwoods. Set up your tent, explore nearby trails, and slow down.',
    latitude: 37.0397,
    longitude: -122.0628,
    pricePerNight: 65,
    siteType: 'Tent',
    maxGuests: 2,
    petFriendly: true,
    conditionsKnown: true,
    fireRule: 'Fire ban in effect · No campfires',
    fireDetail: 'Avoid wood and charcoal fires. Ask the campsite host which cooking equipment is permitted before packing.',
    closures: 'No trail or road closures reported near this campsite.',
  ),
  Campsite(
    id: 'sunset-ridge',
    name: 'Sunset Ridge',
    area: 'Boulder Creek, California',
    image: 'assets/images/5b5ffeae6b8241ad.png',
    description: 'Open mountain views, RV-friendly spaces and room for up to 4 travelers.',
    latitude: 37.1263,
    longitude: -122.1222,
    pricePerNight: 55,
    siteType: 'RV',
    maxGuests: 4,
    petFriendly: false,
    conditionsKnown: false,
    fireRule: 'Fire rules not confirmed',
    fireDetail: 'We couldn’t confirm current fire rules for this site. Check with the host before travelling.',
    closures: 'Closure notices are unavailable for this site.',
  ),
];

/// Campsite catalog plus each user's saved campsites in Firestore.
class CampsiteRepository {
  CampsiteRepository(this._firestore, {this.catalog = campsiteCatalog});

  final FirestoreService _firestore;
  final List<Campsite> catalog;

  List<Campsite> get all => catalog;

  /// Accepts the id or, for older saved data, the display name.
  Campsite? byId(String? idOrName) {
    if (idOrName == null) return null;
    for (final site in catalog) {
      if (site.id == idOrName || site.name == idOrName) return site;
    }
    return null;
  }

  List<Campsite> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return catalog;
    return catalog
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.area.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<Set<String>> savedIds(String uid) async {
    final saved = await _firestore.savedCampsites(uid);
    return {
      for (final item in saved)
        if (byId(item.siteId) != null) byId(item.siteId)!.id,
    };
  }

  Future<void> save(String uid, Campsite site) => _firestore.saveCampsite(
    uid,
    SavedCampsite(siteId: site.id, name: site.name, pricePerNight: site.price),
  );

  Future<void> remove(String uid, Campsite site) async {
    await _firestore.removeCampsite(uid, site.id);
    // Older saves used the name as the document id.
    if (site.name != site.id) {
      await _firestore.removeCampsite(uid, site.name);
    }
  }
}
