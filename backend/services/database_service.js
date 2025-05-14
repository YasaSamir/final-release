/**
 * Database Service
 *
 * Ce service gère le stockage et la récupération des données de l'application.
 * Pour simplifier, nous utilisons une base de données en mémoire (objets JavaScript),
 * mais cela pourrait être remplacé par une vraie base de données comme MongoDB, MySQL, etc.
 */

// In-memory database
const db = {
  rides: [],
  drivers: [],
  riders: [],
  aiPredictions: [], // Collection for AI predictions
  completedRides: [] // Collection for completed rides
};

class DatabaseService {
  constructor() {
    console.log('Database service initialized');
  }

  /**
   * Ajoute une nouvelle demande de trajet
   * @param {Object} rideData - Données du trajet
   * @returns {Object} - La demande de trajet créée avec un ID
   */
  createRide(rideData) {
    const ride = {
      id: `ride_${Date.now()}`,
      ...rideData,
      createdAt: new Date(),
      status: 'pending'
    };

    db.rides.push(ride);
    console.log(`New ride created with ID: ${ride.id}`);

    return ride;
  }

  /**
   * Récupère toutes les demandes de trajet
   * @param {Object} filters - Filtres optionnels
   * @returns {Array} - Liste des demandes de trajet
   */
  getRides(filters = {}) {
    let rides = [...db.rides];

    // Appliquer les filtres
    if (filters.status) {
      rides = rides.filter(ride => ride.status === filters.status);
    }

    if (filters.driverId) {
      rides = rides.filter(ride => ride.driverId === filters.driverId);
    }

    if (filters.riderId) {
      rides = rides.filter(ride => ride.riderId === filters.riderId);
    }

    return rides;
  }

  /**
   * Récupère une demande de trajet par son ID
   * @param {string} rideId - ID de la demande de trajet
   * @returns {Object|null} - La demande de trajet ou null si non trouvée
   */
  getRideById(rideId) {
    return db.rides.find(ride => ride.id === rideId) || null;
  }

  /**
   * Met à jour une demande de trajet
   * @param {string} rideId - ID de la demande de trajet
   * @param {Object} updates - Mises à jour à appliquer
   * @returns {Object|null} - La demande de trajet mise à jour ou null si non trouvée
   */
  updateRide(rideId, updates) {
    const index = db.rides.findIndex(ride => ride.id === rideId);

    if (index === -1) {
      return null;
    }

    // Mettre à jour la demande de trajet
    db.rides[index] = {
      ...db.rides[index],
      ...updates,
      updatedAt: new Date()
    };

    return db.rides[index];
  }

  /**
   * Ajoute un nouveau conducteur
   * @param {Object} driverData - Données du conducteur
   * @returns {Object} - Le conducteur créé avec un ID
   */
  createDriver(driverData) {
    const driver = {
      id: `driver_${Date.now()}`,
      ...driverData,
      createdAt: new Date(),
      isAvailable: true
    };

    db.drivers.push(driver);
    console.log(`New driver created with ID: ${driver.id}`);

    return driver;
  }

  /**
   * Récupère tous les conducteurs
   * @param {Object} filters - Filtres optionnels
   * @returns {Array} - Liste des conducteurs
   */
  getDrivers(filters = {}) {
    let drivers = [...db.drivers];

    // Appliquer les filtres
    if (filters.isAvailable !== undefined) {
      drivers = drivers.filter(driver => driver.isAvailable === filters.isAvailable);
    }

    return drivers;
  }

  /**
   * Récupère un conducteur par son ID
   * @param {string} driverId - ID du conducteur
   * @returns {Object|null} - Le conducteur ou null si non trouvé
   */
  getDriverById(driverId) {
    return db.drivers.find(driver => driver.id === driverId) || null;
  }

  /**
   * Met à jour un conducteur
   * @param {string} driverId - ID du conducteur
   * @param {Object} updates - Mises à jour à appliquer
   * @returns {Object|null} - Le conducteur mis à jour ou null si non trouvé
   */
  updateDriver(driverId, updates) {
    const index = db.drivers.findIndex(driver => driver.id === driverId);

    if (index === -1) {
      return null;
    }

    // Mettre à jour le conducteur
    db.drivers[index] = {
      ...db.drivers[index],
      ...updates,
      updatedAt: new Date()
    };

    return db.drivers[index];
  }

  /**
   * Ajoute un nouveau passager
   * @param {Object} riderData - Données du passager
   * @returns {Object} - Le passager créé avec un ID
   */
  createRider(riderData) {
    const rider = {
      id: `rider_${Date.now()}`,
      ...riderData,
      createdAt: new Date()
    };

    db.riders.push(rider);
    console.log(`New rider created with ID: ${rider.id}`);

    return rider;
  }

  /**
   * Récupère un passager par son ID
   * @param {string} riderId - ID du passager
   * @returns {Object|null} - Le passager ou null si non trouvé
   */
  getRiderById(riderId) {
    return db.riders.find(rider => rider.id === riderId) || null;
  }

  /**
   * Stocke les données de prédiction du modèle AI
   * @param {Object} predictionData - Données de prédiction
   * @returns {Object} - Les données de prédiction stockées
   */
  insertPredictionData(predictionData) {
    const prediction = {
      id: `pred_${Date.now()}`,
      ...predictionData,
      timestamp: new Date()
    };

    db.aiPredictions.push(prediction);
    console.log(`New AI prediction stored with ID: ${prediction.id}`);

    return prediction;
  }

  /**
   * Récupère les données de prédiction du modèle AI
   * @param {number} limit - Nombre maximum de prédictions à récupérer
   * @returns {Array} - Liste des prédictions
   */
  getPredictionData(limit = 100) {
    // Trier par date décroissante et limiter le nombre de résultats
    return [...db.aiPredictions]
      .sort((a, b) => b.timestamp - a.timestamp)
      .slice(0, limit);
  }

  /**
   * Met à jour une demande de trajet avec les données de prédiction AI
   * @param {string} rideId - ID de la demande de trajet
   * @param {Object} predictionData - Données de prédiction AI
   * @returns {Object|null} - La demande de trajet mise à jour ou null si non trouvée
   */
  updateRideWithAIPrediction(rideId, predictionData) {
    const index = db.rides.findIndex(ride => ride.id === rideId);

    if (index === -1) {
      return null;
    }

    // Mettre à jour la demande de trajet avec les données de prédiction AI
    db.rides[index] = {
      ...db.rides[index],
      aiPrediction: predictionData,
      updatedAt: new Date()
    };

    console.log(`Ride ${rideId} updated with AI prediction`);
    return db.rides[index];
  }

  /**
   * Ajoute une demande de partage de trajet
   * @param {string} rideId - ID de la demande de trajet principale
   * @param {Object} sharingData - Données de la demande de partage
   * @returns {Object|null} - La demande de trajet mise à jour ou null si non trouvée
   */
  addRideSharing(rideId, sharingData) {
    const index = db.rides.findIndex(ride => ride.id === rideId);

    if (index === -1) {
      return null;
    }

    // Initialiser le tableau sharedWith s'il n'existe pas
    if (!db.rides[index].sharedWith) {
      db.rides[index].sharedWith = [];
    }

    // Ajouter la demande de partage
    const sharingRequest = {
      id: `share_${Date.now()}`,
      ...sharingData,
      status: 'pending',
      createdAt: new Date()
    };

    db.rides[index].sharedWith.push(sharingRequest);
    db.rides[index].updatedAt = new Date();

    console.log(`Sharing request added to ride ${rideId}`);
    return db.rides[index];
  }

  /**
   * Updates a ride sharing request
   * @param {string} rideId - ID of the main ride
   * @param {string} sharingId - ID of the sharing request
   * @param {Object} updates - Updates to apply
   * @returns {Object|null} - The updated ride or null if not found
   */
  updateRideSharing(rideId, sharingId, updates) {
    const rideIndex = db.rides.findIndex(ride => ride.id === rideId);

    if (rideIndex === -1 || !db.rides[rideIndex].sharedWith) {
      return null;
    }

    const sharingIndex = db.rides[rideIndex].sharedWith.findIndex(
      sharing => sharing.id === sharingId
    );

    if (sharingIndex === -1) {
      return null;
    }

    // Update the sharing request
    db.rides[rideIndex].sharedWith[sharingIndex] = {
      ...db.rides[rideIndex].sharedWith[sharingIndex],
      ...updates,
      updatedAt: new Date()
    };

    db.rides[rideIndex].updatedAt = new Date();

    console.log(`Sharing request ${sharingId} updated for ride ${rideId}`);
    return db.rides[rideIndex];
  }

  /**
   * Stores a completed ride
   * @param {Object} rideData - Completed ride data
   * @returns {Object} - The stored completed ride
   */
  storeCompletedRide(rideData) {
    const completedRide = {
      ...rideData,
      storedAt: new Date()
    };

    // Store in completed rides collection
    db.completedRides.push(completedRide);

    // Also update the original ride if it exists
    const rideIndex = db.rides.findIndex(ride => ride.id === rideData.rideId);
    if (rideIndex !== -1) {
      db.rides[rideIndex] = {
        ...db.rides[rideIndex],
        status: 'completed',
        completedAt: rideData.completedAt || new Date(),
        duration: rideData.duration,
        updatedAt: new Date()
      };
    }

    console.log(`Completed ride stored: ${rideData.rideId}`);
    return completedRide;
  }

  /**
   * Gets completed rides
   * @param {Object} filters - Optional filters
   * @param {number} limit - Maximum number of rides to return
   * @returns {Array} - List of completed rides
   */
  getCompletedRides(filters = {}, limit = 100) {
    let rides = [...db.completedRides];

    // Apply filters
    if (filters.driverId) {
      rides = rides.filter(ride => ride.driverId === filters.driverId);
    }

    if (filters.riderId) {
      rides = rides.filter(ride => ride.riderId === filters.riderId);
    }

    if (filters.priority) {
      rides = rides.filter(ride => ride.priority === filters.priority);
    }

    // Sort by completion time (newest first)
    rides.sort((a, b) => {
      const dateA = a.completedAt ? new Date(a.completedAt) : new Date(0);
      const dateB = b.completedAt ? new Date(b.completedAt) : new Date(0);
      return dateB - dateA;
    });

    // Limit the number of results
    return rides.slice(0, limit);
  }
}

module.exports = new DatabaseService();
