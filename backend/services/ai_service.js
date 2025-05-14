const axios = require('axios');
const { DateTime } = require('luxon');
const dbService = require('./database_service');

class AIService {
  constructor() {
    this.aiServiceUrl = process.env.AI_SERVICE_URL || 'http://localhost:5000';
    this.connectionTimeout = 8000; // 8 seconds timeout for AI service
    this.trainingDataThreshold = 50; // Number of records before retraining
    this.pendingTrainingData = [];
    console.log(`AI Service initialized with endpoint: ${this.aiServiceUrl}`);

    // Check AI service health on startup
    this.checkHealth();

    // Schedule periodic health checks
    setInterval(() => this.checkHealth(), 60000); // Check every minute
  }

  /**
   * Check the health of the AI service
   */
  async checkHealth() {
    try {
      const response = await axios.get(
        `${this.aiServiceUrl}/health`,
        { timeout: this.connectionTimeout }
      );

      console.log(`AI Service health check: ${response.data.status}`);
      return response.data;
    } catch (error) {
      console.error('AI Service health check failed:', error.message);
      return { status: 'unhealthy', error: error.message };
    }
  }

  /**
   * Predict if adding a new rider to an existing ride is beneficial
   *
   * @param {number} originalDistance - Original ride distance in meters
   * @param {number} distanceAfterAddingRider - New distance after adding the rider in meters
   * @param {number} newRiderDistance - Direct distance for the new rider in meters
   * @param {Object} contextData - Additional context data for better predictions
   * @returns {Promise<Object>} - Prediction result with score and decision
   */
  async predictRideSharing(originalDistance, distanceAfterAddingRider, newRiderDistance, contextData = {}) {
    try {
      // Convert distances to kilometers for better model performance
      const originalDistanceKm = originalDistance / 1000;
      const distanceAfterAddingRiderKm = distanceAfterAddingRider / 1000;
      const newRiderDistanceKm = newRiderDistance / 1000;

      // Get current time context
      const now = DateTime.now();

      // Prepare request data with additional context
      const requestData = {
        original_distance: originalDistanceKm,
        distance_after_adding_rider: distanceAfterAddingRiderKm,
        new_rider_distance: newRiderDistanceKm,
        time_of_day: contextData.timeOfDay || now.hour,
        day_of_week: contextData.dayOfWeek || now.weekday - 1, // 0-6, Monday-Sunday
        traffic_level: contextData.trafficLevel || this.estimateTrafficLevel(now.hour),
        weather_condition: contextData.weatherCondition || 0 // Default to clear weather
      };

      console.log('Sending prediction request to AI model with context:', requestData);

      // Call the AI model API with timeout
      const response = await axios.post(
        `${this.aiServiceUrl}/predict`,
        requestData,
        { timeout: this.connectionTimeout }
      );

      // Check if the response is valid
      if (response.status !== 200 || !response.data) {
        throw new Error(`Invalid response from AI model: ${response.status}`);
      }

      // Store prediction in database for future training
      this.storePredictionData(requestData, response.data);

      // Process the prediction
      const result = {
        score: response.data.prediction_score || 0,
        shouldAddRider: response.data.add_rider === true,
        efficiency: response.data.efficiency || this.calculateEfficiency(originalDistanceKm, distanceAfterAddingRiderKm, newRiderDistanceKm),
        fareDetails: response.data.fare_details || this.calculateFareDetails(originalDistanceKm, distanceAfterAddingRiderKm, newRiderDistanceKm),
        environmentalImpact: response.data.environmental_impact || this.calculateEnvironmentalImpact(newRiderDistanceKm),
        aiModelUsed: true,
        contextData: {
          timeOfDay: requestData.time_of_day,
          dayOfWeek: requestData.day_of_week,
          trafficLevel: requestData.traffic_level,
          weatherCondition: requestData.weather_condition
        }
      };

      console.log('AI prediction result:', result);
      return result;
    } catch (error) {
      console.error('Error calling AI model:', error.message);

      // Fallback prediction based on simple heuristic if AI model fails
      return this.fallbackPrediction(originalDistance, distanceAfterAddingRider, newRiderDistance);
    }
  }

  /**
   * Calculate ride sharing efficiency
   *
   * @param {number} originalDistance - Original ride distance in km
   * @param {number} distanceAfterAddingRider - New distance after adding the rider in km
   * @param {number} newRiderDistance - Direct distance for the new rider in km
   * @returns {number} - Efficiency score (higher is better)
   */
  calculateEfficiency(originalDistance, distanceAfterAddingRider, newRiderDistance) {
    // Calculate the additional distance required to accommodate the new rider
    const additionalDistance = distanceAfterAddingRider - originalDistance;

    // Calculate what percentage of the direct route this additional distance represents
    const efficiencyRatio = additionalDistance / newRiderDistance;

    // Convert to a 0-100 scale where 100 is most efficient
    // If additional distance is less than 20% of direct route, it's very efficient
    const efficiency = Math.max(0, 100 - (efficiencyRatio * 100));

    return Math.round(efficiency);
  }

  /**
   * Fallback prediction when AI model is unavailable
   *
   * @param {number} originalDistance - Original ride distance in meters
   * @param {number} distanceAfterAddingRider - New distance after adding the rider in meters
   * @param {number} newRiderDistance - Direct distance for the new rider in meters
   * @returns {Object} - Prediction result with score and decision
   */
  /**
   * Calculate fare details for ride sharing
   *
   * @param {number} originalDistance - Original ride distance in km
   * @param {number} distanceAfterAddingRider - New distance after adding the rider in km
   * @param {number} newRiderDistance - Direct distance for the new rider in km
   * @returns {Object} - Fare details for both riders
   */
  calculateFareDetails(originalDistance, distanceAfterAddingRider, newRiderDistance) {
    // Base fare and per km rate
    const baseFare = 10; // Base fare in currency units
    const perKmRate = 2; // Rate per km in currency units

    // Calculate original fare
    const originalFare = baseFare + (originalDistance * perKmRate);

    // Calculate direct fare for new rider
    const newRiderDirectFare = baseFare + (newRiderDistance * perKmRate);

    // Calculate fare split based on distance ratio
    const originalRiderNewFare = originalFare * 0.7; // 30% discount for original rider
    const newRiderFare = baseFare * 0.5 + (newRiderDistance * perKmRate * 0.8); // 20% discount on distance

    // Calculate savings
    const originalRiderSavings = originalFare - originalRiderNewFare;
    const newRiderSavings = newRiderDirectFare - newRiderFare;
    const totalSavings = originalRiderSavings + newRiderSavings;

    return {
      originalRider: {
        originalFare: Math.round(originalFare),
        newFare: Math.round(originalRiderNewFare),
        savings: Math.round(originalRiderSavings)
      },
      newRider: {
        directFare: Math.round(newRiderDirectFare),
        sharedFare: Math.round(newRiderFare),
        savings: Math.round(newRiderSavings)
      },
      totalSavings: Math.round(totalSavings)
    };
  }

  /**
   * Calculate environmental impact of ride sharing
   *
   * @param {number} newRiderDistance - Direct distance for the new rider in km
   * @returns {Object} - Environmental impact details
   */
  calculateEnvironmentalImpact(newRiderDistance) {
    // Calculate CO2 reduction (0.12 kg per km)
    const co2Reduction = newRiderDistance * 0.12;

    // Calculate fuel saved (0.08 liters per km)
    const fuelSaved = newRiderDistance * 0.08;

    return {
      co2Reduction: Math.round(co2Reduction * 1000) / 1000, // kg of CO2
      fuelSaved: Math.round(fuelSaved * 100) / 100 // liters
    };
  }

  /**
   * Estimate traffic level based on time of day
   *
   * @param {number} hour - Hour of the day (0-23)
   * @returns {number} - Traffic level (0-1)
   */
  estimateTrafficLevel(hour) {
    // Morning rush hour (7-9 AM)
    if (hour >= 7 && hour <= 9) {
      return 0.8;
    }

    // Evening rush hour (4-7 PM)
    if (hour >= 16 && hour <= 19) {
      return 0.9;
    }

    // Late night (11 PM - 5 AM)
    if (hour >= 23 || hour <= 5) {
      return 0.2;
    }

    // Default: medium traffic
    return 0.5;
  }

  /**
   * Store prediction data for future training
   *
   * @param {Object} requestData - Request data sent to AI model
   * @param {Object} responseData - Response data from AI model
   */
  async storePredictionData(requestData, responseData) {
    try {
      // Create training data record
      const trainingData = {
        ...requestData,
        prediction: responseData.add_rider,
        score: responseData.prediction_score,
        timestamp: new Date()
      };

      // Store in database
      // await dbService.insertPredictionData(trainingData);

      // Add to pending training data
      this.pendingTrainingData.push(trainingData);

      // Check if we have enough data to retrain the model
      if (this.pendingTrainingData.length >= this.trainingDataThreshold) {
        await this.retrainModel();
      }

      console.log(`Stored prediction data for training. Pending records: ${this.pendingTrainingData.length}`);
    } catch (error) {
      console.error('Error storing prediction data:', error.message);
    }
  }

  /**
   * Retrain the AI model with new data
   */
  async retrainModel() {
    try {
      if (this.pendingTrainingData.length === 0) {
        console.log('No pending training data. Skipping retraining.');
        return;
      }

      console.log(`Retraining AI model with ${this.pendingTrainingData.length} new records...`);

      // Send training data to AI service
      await axios.post(
        `${this.aiServiceUrl}/train`,
        this.pendingTrainingData,
        { timeout: this.connectionTimeout * 2 } // Double timeout for training
      );

      // Clear pending training data
      this.pendingTrainingData = [];

      console.log('AI model retrained successfully');
    } catch (error) {
      console.error('Error retraining AI model:', error.message);
    }
  }

  fallbackPrediction(originalDistance, distanceAfterAddingRider, newRiderDistance) {
    // Convert to km
    const originalDistanceKm = originalDistance / 1000;
    const distanceAfterAddingRiderKm = distanceAfterAddingRider / 1000;
    const newRiderDistanceKm = newRiderDistance / 1000;

    // Simple heuristic: if adding the rider increases the total distance by less than 30%,
    // and the new rider's direct distance is at least 2km, then it's beneficial
    const additionalDistance = distanceAfterAddingRiderKm - originalDistanceKm;
    const percentageIncrease = (additionalDistance / originalDistanceKm) * 100;

    const shouldAddRider = percentageIncrease < 30 && newRiderDistanceKm >= 2;

    // Calculate a score between 0 and 1
    const score = Math.max(0, Math.min(1, 1 - (percentageIncrease / 100)));

    const efficiency = this.calculateEfficiency(
      originalDistanceKm,
      distanceAfterAddingRiderKm,
      newRiderDistanceKm
    );

    // Calculate fare details
    const fareDetails = this.calculateFareDetails(
      originalDistanceKm,
      distanceAfterAddingRiderKm,
      newRiderDistanceKm
    );

    // Calculate environmental impact
    const environmentalImpact = this.calculateEnvironmentalImpact(newRiderDistanceKm);

    console.log('Using fallback prediction:', {
      score,
      shouldAddRider,
      efficiency,
      percentageIncrease
    });

    return {
      score,
      shouldAddRider,
      efficiency,
      fareDetails,
      environmentalImpact,
      isFallback: true,
      aiModelUsed: false
    };
  }
}

module.exports = new AIService();