const express = require('express');
const axios = require('axios');
const bodyParser = require('body-parser');
const polyline = require('@mapbox/polyline');
const http = require('http');
const socketIO = require('socket.io');
const { v4: uuidv4 } = require('uuid');
const aiService = require('./services/ai_service');
const dbService = require('./services/database_service');

const app = express();
const PORT = process.env.PORT || 3000;

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.IO
const io = socketIO(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// In-memory storage for ride requests
const rideRequests = {};
const driverStatus = {};
let completedRides = [];

// Initialize ride statistics
let rideStats = {
  totalRides: 0,
  completedRides: 0,
  cancelledRides: 0,
  averageDuration: 0,
  highPriorityRides: 0,
  normalPriorityRides: 0,
  lastUpdated: new Date()
};

// Middleware
app.use(bodyParser.json());
app.use(express.static('public'));

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('New client connected:', socket.id);

  // Driver registers as available
  socket.on('driver:available', (driverId) => {
    driverStatus[driverId] = { socketId: socket.id, available: true };
    console.log(`Driver ${driverId} is now available`);
  });

  // Driver registers as unavailable
  socket.on('driver:unavailable', (driverId) => {
    if (driverStatus[driverId]) {
      driverStatus[driverId].available = false;
      console.log(`Driver ${driverId} is now unavailable`);
    }
  });

  // Rider creates a ride request
  socket.on('ride:request', (data) => {
    const rideId = uuidv4();
    const rideRequest = {
      id: rideId,
      riderId: data.riderId,
      pickupLocation: data.pickupLocation,
      destination: data.destination,
      status: 'pending',
      timestamp: new Date(),
      riderSocketId: socket.id,
      priority: data.priority || 'normal', // Allow setting priority from client
      requestedFeatures: data.features || [] // Store requested features
    };

    rideRequests[rideId] = rideRequest;
    console.log(`New ride request created: ${rideId} with priority ${rideRequest.priority}`);

    // Update ride statistics
    rideStats.totalRides++;
    if (rideRequest.priority === 'high') {
      rideStats.highPriorityRides++;
    } else {
      rideStats.normalPriorityRides++;
    }
    rideStats.lastUpdated = new Date();

    // Notify all available drivers
    Object.keys(driverStatus).forEach(driverId => {
      if (driverStatus[driverId].available) {
        io.to(driverStatus[driverId].socketId).emit('ride:new_request', rideRequest);
      }
    });

    // Acknowledge the request creation with estimated duration
    socket.emit('ride:created', {
      rideId,
      estimatedDuration: calculateEstimatedDuration(rideRequest),
      priority: rideRequest.priority,
      timestamp: rideRequest.timestamp
    });
  });

  // Driver accepts a ride
  socket.on('ride:accept', (data) => {
    const { rideId, driverId } = data;

    if (rideRequests[rideId]) {
      // Update ride status with high priority
      rideRequests[rideId].status = 'accepted';
      rideRequests[rideId].driverId = driverId;
      rideRequests[rideId].acceptedAt = new Date();
      rideRequests[rideId].priority = 'high'; // Add priority flag

      console.log(`Ride ${rideId} accepted by driver ${driverId} with high priority`);

      // Notify the rider immediately
      io.to(rideRequests[rideId].riderSocketId).emit('ride:accepted', {
        rideId,
        driverId,
        timestamp: new Date(),
        message: 'Your ride has been accepted',
        priority: 'high',
        estimatedDuration: calculateEstimatedDuration(rideRequests[rideId])
      });

      // Mark driver as unavailable
      if (driverStatus[driverId]) {
        driverStatus[driverId].available = false;
        driverStatus[driverId].currentRideId = rideId;
        driverStatus[driverId].busySince = new Date();
      }

      // Make the ride visible to other users for AI ride sharing
      // This allows the system to suggest ride sharing opportunities
      Object.keys(rideRequests).forEach(otherRideId => {
        if (otherRideId !== rideId && rideRequests[otherRideId].status === 'pending') {
          // Notify riders with pending requests about this active ride
          io.to(rideRequests[otherRideId].riderSocketId).emit('ride:sharing_opportunity', {
            activeRideId: rideId,
            pickupLocation: rideRequests[rideId].pickupLocation,
            destination: rideRequests[rideId].destination,
            driverId: driverId,
            estimatedDuration: calculateEstimatedDuration(rideRequests[rideId])
          });
        }
      });

      console.log(`Ride ${rideId} is now visible for ride sharing opportunities`);

      // Start real-time duration tracking
      startRideDurationTracking(rideId);

      // Simulate driver location updates with improved frequency for high priority rides
      simulateDriverLocationUpdates(rideRequests[rideId], driverId, true);
    } else {
      console.log(`Ride ${rideId} not found for acceptance`);
    }
  });

  // Function to simulate driver location updates
  function simulateDriverLocationUpdates(ride, driverId, highPriority = false) {
    // Initial driver position (slightly away from pickup point)
    const driverStartLat = ride.pickupLocation.lat - 0.005;
    const driverStartLng = ride.pickupLocation.lng - 0.005;

    // Calculate steps to reach pickup point
    const steps = highPriority ? 8 : 10; // Faster for high priority rides
    const latStep = (ride.pickupLocation.lat - driverStartLat) / steps;
    const lngStep = (ride.pickupLocation.lng - driverStartLng) / steps;

    // Update interval - faster for high priority rides
    const updateInterval = highPriority ? 1500 : 2000; // 1.5 seconds for high priority

    // Send position updates
    let currentStep = 0;

    const locationInterval = setInterval(() => {
      if (currentStep <= steps) {
        // Calculate current position
        const currentLat = driverStartLat + (latStep * currentStep);
        const currentLng = driverStartLng + (lngStep * currentStep);

        // Send position update with priority flag
        io.to(ride.riderSocketId).emit('driver:location_update', {
          driverId,
          location: {
            lat: currentLat,
            lng: currentLng
          },
          priority: highPriority ? 'high' : 'normal',
          estimatedArrival: {
            steps: steps - currentStep,
            timeRemaining: ((steps - currentStep) * updateInterval) / 1000
          }
        });

        currentStep++;
      } else {
        // Once arrived at pickup point, simulate journey to destination
        if (ride.status === 'accepted') {
          // Update ride status
          ride.status = 'in_progress';

          // Send ride start notification
          io.to(ride.riderSocketId).emit('ride:started', {
            rideId: ride.id,
            priority: highPriority ? 'high' : 'normal',
            startTime: new Date(),
            estimatedDuration: calculateEstimatedDuration(ride)
          });

          // Simulate journey to destination
          simulateRideToDestination(ride, driverId, highPriority);
        }

        // Stop this interval
        clearInterval(locationInterval);
      }
    }, updateInterval);
  }

  // Function to simulate journey to destination
  function simulateRideToDestination(ride, driverId, highPriority = false) {
    // Calculate steps to reach destination
    const steps = highPriority ? 12 : 15; // Fewer steps for high priority rides
    const latStep = (ride.destination.lat - ride.pickupLocation.lat) / steps;
    const lngStep = (ride.destination.lng - ride.pickupLocation.lng) / steps;

    // Initial position (pickup point)
    let currentLat = ride.pickupLocation.lat;
    let currentLng = ride.pickupLocation.lng;

    // Update interval - faster for high priority rides
    const updateInterval = highPriority ? 1500 : 2000; // 1.5 seconds for high priority

    // Send position updates
    let currentStep = 0;

    // Start real-time duration tracking if not already started
    if (!ride.durationUpdateInterval) {
      startRideDurationTracking(ride.id);
    }

    const locationInterval = setInterval(() => {
      if (currentStep <= steps) {
        // Calculate current position
        currentLat += latStep;
        currentLng += lngStep;

        // Calculate progress percentage
        const progress = Math.round((currentStep / steps) * 100);

        // Send position update with priority flag and progress
        io.to(ride.riderSocketId).emit('driver:location_update', {
          driverId,
          location: {
            lat: currentLat,
            lng: currentLng
          },
          priority: highPriority ? 'high' : 'normal',
          progress: progress,
          estimatedArrival: {
            steps: steps - currentStep,
            timeRemaining: ((steps - currentStep) * updateInterval) / 1000
          }
        });

        currentStep++;
      } else {
        // Once arrived at destination, complete the ride
        ride.status = 'completed';
        ride.completedAt = new Date();

        // Calculate actual duration
        const actualDuration = Math.round((ride.completedAt - ride.startTime) / 1000 / 60);

        // Stop duration tracking
        stopRideDurationTracking(ride.id);

        // Send ride completion notification
        io.to(ride.riderSocketId).emit('ride:completed', {
          rideId: ride.id,
          completedAt: ride.completedAt,
          actualDuration: {
            minutes: actualDuration,
            formatted: `${Math.floor(actualDuration / 60)}h ${actualDuration % 60}m`
          },
          priority: highPriority ? 'high' : 'normal'
        });

        // Make driver available again
        if (driverStatus[driverId]) {
          driverStatus[driverId].available = true;
          driverStatus[driverId].currentRideId = null;
        }

        // Stop this interval
        clearInterval(locationInterval);
      }
    }, updateInterval);
  }

  // Driver rejects a ride
  socket.on('ride:reject', (data) => {
    const { rideId, driverId } = data;

    if (rideRequests[rideId]) {
      console.log(`Ride ${rideId} rejected by driver ${driverId}`);

      // Update ride status in memory
      rideRequests[rideId].status = 'pending'; // Keep it pending so other drivers can accept
      rideRequests[rideId].rejectedBy = rideRequests[rideId].rejectedBy || [];
      rideRequests[rideId].rejectedBy.push(driverId);

      // Add rejection timestamp
      rideRequests[rideId].rejectionTime = new Date();

      // Notify the rider
      io.to(rideRequests[rideId].riderSocketId).emit('ride:rejected', {
        rideId,
        driverId,
        timestamp: new Date(),
        message: 'Driver rejected your ride request'
      });

      // Make ride available to other drivers
      Object.keys(driverStatus).forEach(otherDriverId => {
        // Don't send to drivers who already rejected this ride
        if (driverStatus[otherDriverId].available &&
            otherDriverId !== driverId &&
            (!rideRequests[rideId].rejectedBy || !rideRequests[rideId].rejectedBy.includes(otherDriverId))) {
          io.to(driverStatus[otherDriverId].socketId).emit('ride:new_request', rideRequests[rideId]);
        }
      });

      console.log(`Ride ${rideId} is now available to other drivers after rejection`);
    } else {
      console.log(`Ride ${rideId} not found for rejection`);
    }
  });

  // Driver starts the ride
  socket.on('ride:start', (data) => {
    const { rideId } = data;

    if (rideRequests[rideId]) {
      rideRequests[rideId].status = 'in_progress';
      rideRequests[rideId].startTime = new Date();
      console.log(`Ride ${rideId} started at ${rideRequests[rideId].startTime}`);

      // Start real-time duration tracking
      startRideDurationTracking(rideId);

      // Notify the rider with estimated duration
      io.to(rideRequests[rideId].riderSocketId).emit('ride:started', {
        rideId,
        startTime: rideRequests[rideId].startTime,
        estimatedDuration: calculateEstimatedDuration(rideRequests[rideId]),
        priority: rideRequests[rideId].priority || 'normal'
      });
    }
  });

  // Driver completes the ride
  socket.on('ride:complete', (data) => {
    const { rideId, driverId } = data;

    if (rideRequests[rideId]) {
      rideRequests[rideId].status = 'completed';
      rideRequests[rideId].completedAt = new Date();

      // Calculate actual duration
      const startTime = rideRequests[rideId].startTime || rideRequests[rideId].acceptedAt;
      const actualDuration = Math.round((rideRequests[rideId].completedAt - startTime) / 1000 / 60);

      console.log(`Ride ${rideId} completed. Duration: ${actualDuration} minutes`);

      // Stop duration tracking and synchronization
      stopRideDurationTracking(rideId);
      stopRidersSynchronization(rideId);

      // Notify the rider with completion details
      io.to(rideRequests[rideId].riderSocketId).emit('ride:completed', {
        rideId,
        completedAt: rideRequests[rideId].completedAt,
        actualDuration: {
          minutes: actualDuration,
          formatted: `${Math.floor(actualDuration / 60)}h ${actualDuration % 60}m`
        },
        priority: rideRequests[rideId].priority || 'normal'
      });

      // Mark driver as available again
      if (driverStatus[driverId]) {
        driverStatus[driverId].available = true;
        driverStatus[driverId].currentRideId = null;
        driverStatus[driverId].busySince = null;
      }

      // Store ride data for analytics
      const rideData = {
        rideId,
        driverId,
        riderId: rideRequests[rideId].riderId,
        startTime: startTime,
        completedAt: rideRequests[rideId].completedAt,
        duration: actualDuration,
        priority: rideRequests[rideId].priority || 'normal',
        distance: calculateEstimatedDuration(rideRequests[rideId]).distance,
        pickupLocation: rideRequests[rideId].pickupLocation,
        destination: rideRequests[rideId].destination,
        sharedRide: rideRequests[rideId].sharedRiders && rideRequests[rideId].sharedRiders.length > 0
      };

      completedRides.push(rideData);

      // Update ride statistics
      rideStats.completedRides++;

      // Update average duration
      const totalDurations = completedRides.reduce((sum, ride) => sum + ride.duration, 0);
      rideStats.averageDuration = Math.round(totalDurations / completedRides.length);
      rideStats.lastUpdated = new Date();

      // Store in database for persistence
      try {
        dbService.storeCompletedRide(rideData);
      } catch (error) {
        console.error('Error storing completed ride data:', error);
      }

      // Limit the in-memory array size
      if (completedRides.length > 100) {
        completedRides = completedRides.slice(-100); // Keep only the last 100 rides
      }
    }
  });

  // Driver location updates
  socket.on('driver:location', (data) => {
    const { rideId, driverId, location } = data;

    console.log(`Driver ${driverId} location update for ride ${rideId}:`, location);

    if (rideRequests[rideId]) {
      // Update the ride's current location
      rideRequests[rideId].currentLocation = location;
      rideRequests[rideId].lastLocationUpdate = new Date();

      // Calculate and update ETA if we have destination
      if (rideRequests[rideId].destination) {
        // In a real app, you would use a routing service to calculate ETA
        // Here we'll use a simple approximation
        const distanceToDestination = calculateSimpleDistance(
          location.lat,
          location.lng,
          rideRequests[rideId].destination.lat,
          rideRequests[rideId].destination.lng
        );

        // Assuming average speed of 30 km/h
        const etaInMinutes = Math.round((distanceToDestination / 1000) / 30 * 60);
        rideRequests[rideId].eta = etaInMinutes;

        // Calculate progress percentage
        const totalDistance = calculateSimpleDistance(
          rideRequests[rideId].pickupLocation.lat,
          rideRequests[rideId].pickupLocation.lng,
          rideRequests[rideId].destination.lat,
          rideRequests[rideId].destination.lng
        );

        const progress = Math.min(100, Math.round(((totalDistance - distanceToDestination) / totalDistance) * 100));
        rideRequests[rideId].progress = progress;

        console.log(`Updated ETA for ride ${rideId}: ${etaInMinutes} minutes, Progress: ${progress}%`);
      }

      // Get real-time duration information
      const durationInfo = {
        elapsed: rideRequests[rideId].elapsedTime,
        remaining: rideRequests[rideId].remainingTime
      };

      // Forward driver's location to the rider with enhanced information
      io.to(rideRequests[rideId].riderSocketId).emit('driver:location_update', {
        rideId,
        driverId,
        location,
        eta: rideRequests[rideId].eta,
        progress: rideRequests[rideId].progress || 0,
        priority: rideRequests[rideId].priority || 'normal',
        timestamp: rideRequests[rideId].lastLocationUpdate,
        duration: durationInfo,
        sync: {
          id: `sync_${Date.now()}`,
          timestamp: new Date()
        }
      });

      // Forward to any shared riders with the same enhanced information
      if (rideRequests[rideId].sharedRiders && rideRequests[rideId].sharedRiders.length > 0) {
        rideRequests[rideId].sharedRiders.forEach(sharedRider => {
          if (sharedRider.socketId) {
            io.to(sharedRider.socketId).emit('driver:location_update', {
              rideId,
              driverId,
              location,
              eta: rideRequests[rideId].eta,
              progress: rideRequests[rideId].progress || 0,
              priority: rideRequests[rideId].priority || 'normal',
              timestamp: rideRequests[rideId].lastLocationUpdate,
              duration: durationInfo,
              sync: {
                id: `sync_${Date.now()}`,
                timestamp: new Date()
              }
            });
          }
        });
      }

      // Update driver status
      if (driverStatus[driverId]) {
        driverStatus[driverId].location = location;
        driverStatus[driverId].lastUpdate = new Date();
      }

      // Send acknowledgment back to driver
      socket.emit('driver:location_ack', {
        rideId,
        received: true,
        timestamp: new Date(),
        progress: rideRequests[rideId].progress || 0
      });
    }
  });

  // Simple distance calculation using Haversine formula
  function calculateSimpleDistance(lat1, lon1, lat2, lon2) {
    const R = 6371e3; // Earth radius in meters
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lon2 - lon1) * Math.PI / 180;

    const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ/2) * Math.sin(Δλ/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

    return R * c; // Distance in meters
  }

  // Ride sharing request
  socket.on('ride:sharing_request', async (data) => {
    const { rideId, newRiderId, newPickupLocation, newDestination, priority } = data;

    if (rideRequests[rideId] && (rideRequests[rideId].status === 'in_progress' || rideRequests[rideId].status === 'accepted')) {
      try {
        console.log(`Processing ride sharing request for ride ${rideId} from rider ${newRiderId}`);

        // Calculate original route distance
        const originalDistance = await calculateRouteDistance(
          rideRequests[rideId].pickupLocation,
          rideRequests[rideId].destination
        );

        // Calculate new route with detour
        const newRouteDistance = await calculateRouteDistance(
          rideRequests[rideId].currentLocation || rideRequests[rideId].pickupLocation,
          newPickupLocation,
          newDestination,
          rideRequests[rideId].destination
        );

        // Calculate new rider direct distance
        const newRiderDistance = await calculateRouteDistance(
          newPickupLocation,
          newDestination
        );

        console.log('Calling AI service with distances:', {
          originalDistance,
          newRouteDistance,
          newRiderDistance
        });

        // Use AI service to predict if ride sharing is beneficial
        const prediction = await aiService.predictRideSharing(
          originalDistance,
          newRouteDistance,
          newRiderDistance
        );

        console.log('AI prediction result:', prediction);

        // Calculate fare details
        const baseFare = 10; // Base fare in currency units
        const perKmRate = 2; // Rate per km in currency units

        // Original rider's fare
        const originalFare = baseFare + ((originalDistance / 1000) * perKmRate);

        // New rider's direct fare (if they took their own ride)
        const newRiderDirectFare = baseFare + ((newRiderDistance / 1000) * perKmRate);

        // Additional distance cost
        const additionalDistance = newRouteDistance - originalDistance;
        const additionalDistanceCost = (additionalDistance / 1000) * perKmRate;

        // Calculate fare split based on distance ratio
        const originalRiderNewFare = originalFare * 0.7; // 30% discount for original rider
        const newRiderFare = baseFare * 0.5 + ((newRiderDistance / 1000) * perKmRate * 0.8); // 20% discount on distance

        // Calculate savings
        const originalRiderSavings = originalFare - originalRiderNewFare;
        const newRiderSavings = newRiderDirectFare - newRiderFare;
        const totalSavings = originalRiderSavings + newRiderSavings;

        // Add additional information to the prediction
        const enhancedPrediction = {
          ...prediction,
          originalDistance,
          newRouteDistance,
          newRiderDistance,
          additionalDistance,
          additionalTimeEstimate: Math.round((additionalDistance / 1000) / 30 * 60 * 60), // Assuming 30 km/h average speed, convert to seconds
          fareDetails: {
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
          },
          environmentalImpact: {
            co2Reduction: Math.round((newRiderDistance / 1000) * 0.12 * 1000) / 1000, // kg of CO2 saved (0.12 kg per km)
            fuelSaved: Math.round((newRiderDistance / 1000) * 0.08 * 100) / 100 // liters of fuel saved (0.08L per km)
          }
        };

        // Store the sharing request in the ride object
        if (!rideRequests[rideId].sharingRequests) {
          rideRequests[rideId].sharingRequests = [];
        }

        const sharingRequestId = `share_${Date.now()}`;
        const timestamp = new Date();

        // Set priority based on input or prediction score
        const requestPriority = priority ||
          (enhancedPrediction.score > 0.7 ? 'high' : 'normal');

        // Create sharing request with enhanced data
        const sharingRequest = {
          id: sharingRequestId,
          newRiderId,
          newRiderSocketId: socket.id, // Store socket ID for real-time updates
          newPickupLocation,
          newDestination,
          prediction: enhancedPrediction,
          status: 'pending',
          timestamp: timestamp,
          priority: requestPriority,
          syncId: `sync_${Date.now()}`,
          estimatedPickupTime: Math.round(enhancedPrediction.additionalTimeEstimate / 2) // Half the additional time
        };

        rideRequests[rideId].sharingRequests.push(sharingRequest);

        // Notify the driver about the ride sharing request with enhanced data
        io.to(driverStatus[rideRequests[rideId].driverId].socketId).emit('ride:sharing_request', {
          rideId,
          sharingRequestId,
          newRiderId,
          newPickupLocation,
          newDestination,
          prediction: enhancedPrediction,
          priority: sharingRequest.priority,
          timestamp: sharingRequest.timestamp,
          syncId: sharingRequest.syncId,
          estimatedPickupTime: sharingRequest.estimatedPickupTime
        });

        // Acknowledge the request with enhanced data
        socket.emit('ride:sharing_requested', {
          success: true,
          message: 'Ride sharing request sent to driver',
          sharingRequestId,
          prediction: enhancedPrediction,
          priority: sharingRequest.priority,
          timestamp: sharingRequest.timestamp,
          syncId: sharingRequest.syncId,
          estimatedPickupTime: sharingRequest.estimatedPickupTime,
          estimatedWaitTime: sharingRequest.estimatedPickupTime
        });

        // Make the sharing request visible to other potential riders
        // This allows the system to show active ride sharing opportunities
        Object.keys(driverStatus).forEach(otherDriverId => {
          if (driverStatus[otherDriverId].available && otherDriverId !== rideRequests[rideId].driverId) {
            io.to(driverStatus[otherDriverId].socketId).emit('ride:sharing_opportunity', {
              rideId,
              sharingRequestId,
              prediction: enhancedPrediction,
              priority: sharingRequest.priority,
              timestamp: sharingRequest.timestamp,
              syncId: sharingRequest.syncId,
              estimatedPickupTime: sharingRequest.estimatedPickupTime,
              currentRideStatus: rideRequests[rideId].status,
              currentRideProgress: rideRequests[rideId].progress || 0
            });
          }
        });

        console.log(`Ride sharing request ${sharingRequestId} processed successfully`);
      } catch (error) {
        console.error('Error processing ride sharing request:', error);
        socket.emit('ride:sharing_requested', {
          success: false,
          message: 'Failed to process ride sharing request: ' + error.message
        });
      }
    } else {
      socket.emit('ride:sharing_requested', {
        success: false,
        message: 'No active ride found with the provided ID'
      });
    }
  });

  // Driver responds to ride sharing request
  socket.on('ride:sharing_response', (data) => {
    const { rideId, sharingRequestId, accepted, driverId } = data;

    console.log(`Driver ${driverId} ${accepted ? 'accepted' : 'rejected'} sharing request ${sharingRequestId} for ride ${rideId}`);

    if (rideRequests[rideId] && rideRequests[rideId].sharingRequests) {
      // Find the specific sharing request
      const sharingRequest = rideRequests[rideId].sharingRequests.find(
        req => req.id === sharingRequestId
      );

      if (!sharingRequest) {
        console.error(`Sharing request ${sharingRequestId} not found for ride ${rideId}`);
        return;
      }

      // Update the sharing request status
      sharingRequest.status = accepted ? 'accepted' : 'rejected';
      sharingRequest.responseTime = new Date();
      sharingRequest.responseDelay = new Date() - new Date(sharingRequest.timestamp || 0);

      const newRiderId = sharingRequest.newRiderId;
      const newRiderSocketId = sharingRequest.newRiderSocketId;

      if (accepted) {
        // Update ride request to include the new rider with priority
        if (!rideRequests[rideId].sharedRiders) {
          rideRequests[rideId].sharedRiders = [];
        }

        // Create shared rider entry with enhanced data
        const sharedRider = {
          riderId: newRiderId,
          socketId: newRiderSocketId,
          pickupLocation: sharingRequest.newPickupLocation,
          destination: sharingRequest.newDestination,
          status: 'accepted',
          joinedAt: new Date(),
          priority: sharingRequest.priority || 'normal',
          prediction: sharingRequest.prediction,
          syncId: `sync_${Date.now()}`,
          estimatedPickupTime: sharingRequest.estimatedPickupTime || 5
        };

        rideRequests[rideId].sharedRiders.push(sharedRider);

        console.log(`Added rider ${newRiderId} to shared riders for ride ${rideId} with priority ${sharedRider.priority}`);

        // Calculate estimated arrival time
        const estimatedArrival = new Date();
        estimatedArrival.setMinutes(estimatedArrival.getMinutes() + sharedRider.estimatedPickupTime);

        // Notify the new rider with enhanced data
        if (newRiderSocketId) {
          io.to(newRiderSocketId).emit('ride:sharing_accepted', {
            rideId,
            sharingRequestId,
            driverId,
            prediction: sharingRequest.prediction,
            estimatedPickupTime: sharedRider.estimatedPickupTime * 60, // Convert to seconds
            priority: sharedRider.priority,
            timestamp: new Date(),
            syncId: sharedRider.syncId,
            estimatedArrival: estimatedArrival,
            driverLocation: rideRequests[rideId].currentLocation,
            currentRideProgress: rideRequests[rideId].progress || 0
          });
        }

        // Notify the original rider with enhanced data
        io.to(rideRequests[rideId].riderSocketId).emit('ride:sharing_added', {
          rideId,
          sharingRequestId,
          newRiderId,
          prediction: sharingRequest.prediction,
          priority: sharedRider.priority,
          timestamp: new Date(),
          syncId: sharedRider.syncId,
          newPickupLocation: sharingRequest.newPickupLocation,
          newDestination: sharingRequest.newDestination
        });

        // Update the ride's route to include the new pickup and destination
        if (!rideRequests[rideId].route) {
          rideRequests[rideId].route = [];
        }

        // Add the new pickup and destination to the route with priority
        rideRequests[rideId].route.push({
          location: sharingRequest.newPickupLocation,
          type: 'pickup',
          riderId: newRiderId,
          priority: sharedRider.priority,
          estimatedArrival: estimatedArrival
        });

        rideRequests[rideId].route.push({
          location: sharingRequest.newDestination,
          type: 'destination',
          riderId: newRiderId,
          priority: sharedRider.priority
        });

        // Sort route by priority (high priority first)
        rideRequests[rideId].route.sort((a, b) => {
          if (a.priority === 'high' && b.priority !== 'high') return -1;
          if (a.priority !== 'high' && b.priority === 'high') return 1;
          return 0;
        });

        // Start real-time synchronization between riders if not already started
        if (!rideRequests[rideId].syncInterval) {
          startRidersSynchronization(rideId);
        }

        // Log the acceptance for analytics
        console.log(`Ride sharing accepted for ride ${rideId}, new rider: ${newRiderId}, driver: ${driverId}, priority: ${sharedRider.priority}`);

        // Notify other potential riders that this sharing opportunity is no longer available
        Object.keys(driverStatus).forEach(otherDriverId => {
          if (driverStatus[otherDriverId].available && otherDriverId !== driverId) {
            io.to(driverStatus[otherDriverId].socketId).emit('ride:sharing_opportunity_taken', {
              rideId,
              sharingRequestId,
              timestamp: new Date()
            });
          }
        });
      } else {
        // Notify the new rider that the request was rejected with enhanced data
        if (newRiderSocketId) {
          io.to(newRiderSocketId).emit('ride:sharing_rejected', {
            rideId,
            sharingRequestId,
            driverId,
            reason: data.reason || 'Driver declined the request',
            timestamp: new Date(),
            alternatives: {
              message: 'You can try requesting a new ride or try another sharing opportunity',
              availableRides: Object.values(rideRequests)
                .filter(r => r.status === 'in_progress' && r.id !== rideId)
                .map(r => ({
                  rideId: r.id,
                  driverId: r.driverId,
                  currentLocation: r.currentLocation,
                  destination: r.destination
                }))
                .slice(0, 3) // Limit to 3 alternatives
            }
          });
        }

        // Log the rejection for analytics
        console.log(`Ride sharing rejected for ride ${rideId}, new rider: ${newRiderId}, driver: ${driverId}, reason: ${data.reason || 'Not provided'}`);
      }
    } else {
      console.error(`Ride ${rideId} not found or has no sharing requests`);
    }
  });

  // Handle disconnection
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);

    // Check if it was a driver and update status
    Object.keys(driverStatus).forEach(driverId => {
      if (driverStatus[driverId].socketId === socket.id) {
        console.log(`Driver ${driverId} disconnected`);
        delete driverStatus[driverId];
      }
    });
  });
});

// Calculate estimated ride duration based on distance
function calculateEstimatedDuration(ride) {
  // Calculate distance between pickup and destination (simplified)
  const pickupLat = ride.pickupLocation.lat;
  const pickupLng = ride.pickupLocation.lng;
  const destLat = ride.destination.lat;
  const destLng = ride.destination.lng;

  // Simple Haversine formula to calculate distance
  const R = 6371; // Earth's radius in km
  const dLat = (destLat - pickupLat) * Math.PI / 180;
  const dLng = (destLng - pickupLng) * Math.PI / 180;
  const a =
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(pickupLat * Math.PI / 180) * Math.cos(destLat * Math.PI / 180) *
    Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance = R * c; // Distance in km

  // Estimate duration: assume average speed of 30 km/h
  const durationMinutes = Math.round((distance / 30) * 60);

  // Return duration in minutes and formatted time
  return {
    minutes: durationMinutes,
    formatted: `${Math.floor(durationMinutes / 60)}h ${durationMinutes % 60}m`,
    distance: Math.round(distance * 10) / 10 // Distance in km with 1 decimal
  };
}

// Start real-time duration tracking for a ride
function startRideDurationTracking(rideId) {
  const ride = rideRequests[rideId];
  if (!ride) return;

  // Set start time if not already set
  ride.startTime = ride.startTime || new Date();
  ride.durationUpdateInterval = setInterval(() => {
    // Calculate elapsed time
    const now = new Date();
    const elapsedMs = now - ride.startTime;
    const elapsedMinutes = Math.floor(elapsedMs / (1000 * 60));
    const elapsedSeconds = Math.floor((elapsedMs % (1000 * 60)) / 1000);

    // Format elapsed time
    ride.elapsedTime = {
      minutes: elapsedMinutes,
      seconds: elapsedSeconds,
      formatted: `${elapsedMinutes}m ${elapsedSeconds}s`,
      totalSeconds: Math.floor(elapsedMs / 1000)
    };

    // Calculate remaining time
    const estimatedDuration = calculateEstimatedDuration(ride);
    const remainingMinutes = Math.max(0, estimatedDuration.minutes - elapsedMinutes);
    const remainingSeconds = Math.max(0, 60 - elapsedSeconds);

    ride.remainingTime = {
      minutes: remainingMinutes,
      seconds: remainingSeconds,
      formatted: `${remainingMinutes}m ${remainingSeconds}s`,
      totalSeconds: Math.max(0, (remainingMinutes * 60) + remainingSeconds)
    };

    // Send updates to both rider and driver
    if (ride.riderSocketId) {
      io.to(ride.riderSocketId).emit('ride:duration_update', {
        rideId,
        elapsed: ride.elapsedTime,
        remaining: ride.remainingTime,
        timestamp: now
      });
    }

    if (ride.driverId && driverStatus[ride.driverId] && driverStatus[ride.driverId].socketId) {
      io.to(driverStatus[ride.driverId].socketId).emit('ride:duration_update', {
        rideId,
        elapsed: ride.elapsedTime,
        remaining: ride.remainingTime,
        timestamp: now
      });
    }

  }, 1000); // Update every second

  console.log(`Started real-time duration tracking for ride ${rideId}`);
}

// Stop duration tracking for a ride
function stopRideDurationTracking(rideId) {
  const ride = rideRequests[rideId];
  if (!ride || !ride.durationUpdateInterval) return;

  clearInterval(ride.durationUpdateInterval);
  ride.durationUpdateInterval = null;

  console.log(`Stopped real-time duration tracking for ride ${rideId}`);
}

// Start real-time synchronization between riders in a shared ride
function startRidersSynchronization(rideId) {
  const ride = rideRequests[rideId];
  if (!ride || ride.syncInterval) return;

  // Create a synchronization interval that runs every 2 seconds
  ride.syncInterval = setInterval(() => {
    // Skip if no shared riders
    if (!ride.sharedRiders || ride.sharedRiders.length === 0) return;

    // Create synchronization data
    const syncData = {
      rideId,
      timestamp: new Date(),
      syncId: `sync_${Date.now()}`,
      driverLocation: ride.currentLocation,
      status: ride.status,
      progress: ride.progress || 0,
      elapsedTime: ride.elapsedTime,
      remainingTime: ride.remainingTime,
      route: ride.route,
      sharedRidersCount: ride.sharedRiders.length
    };

    // Send to original rider
    if (ride.riderSocketId) {
      io.to(ride.riderSocketId).emit('ride:sync', syncData);
    }

    // Send to all shared riders
    ride.sharedRiders.forEach(sharedRider => {
      if (sharedRider.socketId) {
        io.to(sharedRider.socketId).emit('ride:sync', {
          ...syncData,
          // Add rider-specific data
          yourPickupLocation: sharedRider.pickupLocation,
          yourDestination: sharedRider.destination,
          yourPriority: sharedRider.priority
        });
      }
    });

    // Send to driver
    if (ride.driverId && driverStatus[ride.driverId] && driverStatus[ride.driverId].socketId) {
      io.to(driverStatus[ride.driverId].socketId).emit('ride:sync', {
        ...syncData,
        // Add driver-specific data
        isDriver: true,
        originalRider: {
          riderId: ride.riderId,
          pickupLocation: ride.pickupLocation,
          destination: ride.destination
        },
        sharedRiders: ride.sharedRiders.map(sr => ({
          riderId: sr.riderId,
          pickupLocation: sr.pickupLocation,
          destination: sr.destination,
          priority: sr.priority
        }))
      });
    }
  }, 2000); // Sync every 2 seconds

  console.log(`Started real-time synchronization for shared ride ${rideId}`);
}

// Stop synchronization for a ride
function stopRidersSynchronization(rideId) {
  const ride = rideRequests[rideId];
  if (!ride || !ride.syncInterval) return;

  clearInterval(ride.syncInterval);
  ride.syncInterval = null;

  console.log(`Stopped real-time synchronization for shared ride ${rideId}`);
}

// Helper function to calculate route distance
async function calculateRouteDistance(...waypoints) {
  try {
    // Format waypoints for OSRM API
    const waypointsStr = waypoints
      .map(point => `${point.lng},${point.lat}`)
      .join(';');

    const url = `https://router.project-osrm.org/route/v1/driving/${waypointsStr}?overview=false`;
    const response = await axios.get(url);

    if (response.data.code !== 'Ok' || response.data.routes.length === 0) {
      throw new Error('Failed to calculate route');
    }

    return response.data.routes[0].distance; // Distance in meters
  } catch (error) {
    console.error('Error calculating route distance:', error);
    throw error;
  }
}

// Home page
app.get('/', (req, res) => {
  res.sendFile(__dirname + '/public/index.html');
});

// API endpoint to get completed rides
app.get('/api/rides/completed', (req, res) => {
  try {
    const { driverId, riderId, priority, limit } = req.query;
    const filters = {};

    if (driverId) filters.driverId = driverId;
    if (riderId) filters.riderId = riderId;
    if (priority) filters.priority = priority;

    // Get completed rides from database
    const dbCompletedRides = dbService.getCompletedRides(filters, parseInt(limit) || 100);

    // Combine with in-memory completed rides
    const allCompletedRides = [
      ...completedRides.filter(ride => {
        let match = true;
        if (driverId && ride.driverId !== driverId) match = false;
        if (riderId && ride.riderId !== riderId) match = false;
        if (priority && ride.priority !== priority) match = false;
        return match;
      }),
      ...dbCompletedRides
    ];

    // Remove duplicates
    const uniqueRides = [];
    const rideIds = new Set();

    allCompletedRides.forEach(ride => {
      if (!rideIds.has(ride.rideId)) {
        rideIds.add(ride.rideId);
        uniqueRides.push(ride);
      }
    });

    // Sort by completion time (newest first)
    uniqueRides.sort((a, b) => {
      const dateA = a.completedAt ? new Date(a.completedAt) : new Date(0);
      const dateB = b.completedAt ? new Date(b.completedAt) : new Date(0);
      return dateB - dateA;
    });

    // Limit the number of results
    const limitedRides = uniqueRides.slice(0, parseInt(limit) || 100);

    res.json({
      success: true,
      count: limitedRides.length,
      rides: limitedRides
    });
  } catch (error) {
    console.error('Error retrieving completed rides:', error);
    res.status(500).json({
      success: false,
      message: `Error retrieving completed rides: ${error.message}`
    });
  }
});

// API endpoint to get ride statistics
app.get('/api/rides/stats', (req, res) => {
  try {
    // Calculate active rides
    const activeRides = Object.values(rideRequests).filter(
      ride => ride.status === 'accepted' || ride.status === 'in_progress'
    ).length;

    // Calculate pending rides
    const pendingRides = Object.values(rideRequests).filter(
      ride => ride.status === 'pending'
    ).length;

    // Get available drivers count
    const availableDrivers = Object.values(driverStatus).filter(
      driver => driver.available
    ).length;

    // Get busy drivers count
    const busyDrivers = Object.values(driverStatus).filter(
      driver => !driver.available
    ).length;

    // Enhanced statistics
    const enhancedStats = {
      ...rideStats,
      activeRides,
      pendingRides,
      availableDrivers,
      busyDrivers,
      totalDrivers: availableDrivers + busyDrivers,
      recentCompletedRides: completedRides.slice(-10), // Last 10 completed rides
      timestamp: new Date()
    };

    res.json({
      success: true,
      stats: enhancedStats
    });
  } catch (error) {
    console.error('Error getting ride statistics:', error);
    res.status(500).json({
      success: false,
      message: `Error getting ride statistics: ${error.message}`
    });
  }
});

// API endpoint to get route between two points
app.get('/api/route', async (req, res) => {
  try {
    const { startLat, startLng, endLat, endLng } = req.query;

    // Validate coordinates
    if (!startLat || !startLng || !endLat || !endLng) {
      return res.status(400).json({
        success: false,
        message: 'Missing coordinates: startLat, startLng, endLat, and endLng are required'
      });
    }

    // Query from OSRM service
    const url = `https://router.project-osrm.org/route/v1/driving/` +
                `${startLng},${startLat};${endLng},${endLat}` +
                `?overview=full&geometries=polyline`;

    console.log(`Requesting route from OSRM: ${url}`);

    const response = await axios.get(url);

    if (response.data.code !== 'Ok') {
      throw new Error(`OSRM API error: ${response.data.code} - ${response.data.message || 'No error message'}`);
    }

    if (response.data.routes.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No route found'
      });
    }

    // Extract route data
    const route = response.data.routes[0];
    const encodedPolyline = route.geometry;
    const decodedPolyline = polyline.decode(encodedPolyline);

    // Convert points to [lat, lng] format
    const points = decodedPolyline.map(point => ({
      lat: point[0],
      lng: point[1]
    }));

    // Prepare response data
    const routeData = {
      success: true,
      distance: route.distance, // Distance in meters
      duration: route.duration, // Duration in seconds
      points: points,
      encoded_polyline: encodedPolyline
    };

    res.json(routeData);
  } catch (error) {
    console.error('Error fetching route:', error);
    res.status(500).json({
      success: false,
      message: `Failed to get route: ${error.message}`
    });
  }
});

// API to create a new ride request
app.post('/api/rides', (req, res) => {
  try {
    const { riderId, pickupLocation, destination, priority } = req.body;

    // Verify required data
    if (!riderId || !pickupLocation || !destination) {
      return res.status(400).json({
        success: false,
        message: 'Missing data: riderId, pickupLocation, and destination are required'
      });
    }

    // Create ride request in database
    const ride = dbService.createRide({
      riderId,
      pickupLocation,
      destination,
      status: 'pending',
      timestamp: new Date(),
      priority: priority || 'normal'
    });

    console.log(`New ride request created via API: ${ride.id} with priority ${ride.priority}`);

    // Notify all available drivers via Socket.IO
    Object.keys(driverStatus).forEach(driverId => {
      if (driverStatus[driverId].available) {
        io.to(driverStatus[driverId].socketId).emit('ride:new_request', ride);
      }
    });

    // Calculate estimated duration
    const estimatedDuration = {
      minutes: Math.round(ride.estimatedDuration || 15),
      formatted: `${Math.floor((ride.estimatedDuration || 15) / 60)}h ${(ride.estimatedDuration || 15) % 60}m`
    };

    res.status(201).json({
      success: true,
      rideId: ride.id,
      message: 'Ride request created successfully',
      estimatedDuration,
      priority: ride.priority
    });
  } catch (error) {
    console.error('Error creating ride request:', error);
    res.status(500).json({
      success: false,
      message: `Error creating ride request: ${error.message}`
    });
  }
});

// API to get rides
app.get('/api/rides', (req, res) => {
  try {
    const { status, driverId, riderId, active } = req.query;

    // If active=true is specified, return in-memory active rides
    if (active === 'true') {
      const activeRides = Object.values(rideRequests).filter(ride => {
        let match = true;
        if (status && ride.status !== status) match = false;
        if (driverId && ride.driverId !== driverId) match = false;
        if (riderId && ride.riderId !== riderId) match = false;
        return match;
      }).map(ride => ({
        ...ride,
        estimatedDuration: calculateEstimatedDuration(ride),
        elapsedTime: ride.elapsedTime,
        remainingTime: ride.remainingTime,
        progress: ride.progress || 0,
        isActive: true,
        lastUpdate: new Date()
      }));

      return res.json({
        success: true,
        count: activeRides.length,
        rides: activeRides
      });
    }

    // Otherwise, get rides from database
    const filters = {};
    if (status) filters.status = status;
    if (driverId) filters.driverId = driverId;
    if (riderId) filters.riderId = riderId;

    const rides = dbService.getRides(filters);

    res.json({
      success: true,
      count: rides.length,
      rides
    });
  } catch (error) {
    console.error('Error retrieving rides:', error);
    res.status(500).json({
      success: false,
      message: `Error retrieving rides: ${error.message}`
    });
  }
});

// API to get a ride by its ID
app.get('/api/rides/:rideId', (req, res) => {
  try {
    const { rideId } = req.params;

    // First check in-memory rides (for active rides)
    if (rideRequests[rideId]) {
      const ride = rideRequests[rideId];

      // Add real-time information
      const enhancedRide = {
        ...ride,
        estimatedDuration: calculateEstimatedDuration(ride),
        elapsedTime: ride.elapsedTime,
        remainingTime: ride.remainingTime,
        progress: ride.progress || 0,
        isActive: true,
        lastUpdate: new Date()
      };

      return res.json({
        success: true,
        ride: enhancedRide
      });
    }

    // If not found in memory, check completed rides
    const completedRide = completedRides.find(r => r.rideId === rideId);
    if (completedRide) {
      return res.json({
        success: true,
        ride: {
          ...completedRide,
          isActive: false,
          status: 'completed'
        }
      });
    }

    // If not found in memory, check database
    const ride = dbService.getRideById(rideId);
    if (!ride) {
      return res.status(404).json({
        success: false,
        message: `Ride not found: ${rideId}`
      });
    }

    res.json({
      success: true,
      ride
    });
  } catch (error) {
    console.error('Error retrieving ride:', error);
    res.status(500).json({
      success: false,
      message: `Error retrieving ride: ${error.message}`
    });
  }
});

// API pour mettre à jour une demande de trajet
app.put('/api/rides/:rideId', (req, res) => {
  try {
    const { rideId } = req.params;
    const updates = req.body;

    // Vérifier si la demande de trajet existe
    const existingRide = dbService.getRideById(rideId);
    if (!existingRide) {
      return res.status(404).json({
        success: false,
        message: `Demande de trajet non trouvée: ${rideId}`
      });
    }

    // Mettre à jour la demande de trajet
    const updatedRide = dbService.updateRide(rideId, updates);

    // Si le statut a changé, émettre l'événement correspondant via Socket.IO
    if (updates.status && updates.status !== existingRide.status) {
      if (updates.status === 'accepted' && updates.driverId) {
        io.to(existingRide.riderSocketId).emit('ride:accepted', {
          rideId,
          driverId: updates.driverId
        });
      } else if (updates.status === 'in_progress') {
        io.to(existingRide.riderSocketId).emit('ride:started', { rideId });
      } else if (updates.status === 'completed') {
        io.to(existingRide.riderSocketId).emit('ride:completed', { rideId });
      }
    }

    res.json({
      success: true,
      ride: updatedRide
    });
  } catch (error) {
    console.error('Erreur lors de la mise à jour de la demande de trajet:', error);
    res.status(500).json({
      success: false,
      message: `Erreur lors de la mise à jour de la demande de trajet: ${error.message}`
    });
  }
});

// API pour enregistrer un nouveau conducteur
app.post('/api/drivers', (req, res) => {
  try {
    const { name, vehicleType, vehicleNumber, latitude, longitude } = req.body;

    // Vérifier les données requises
    if (!name || !vehicleType || !vehicleNumber) {
      return res.status(400).json({
        success: false,
        message: 'Données manquantes: name, vehicleType et vehicleNumber sont requis'
      });
    }

    // Créer le conducteur dans la base de données
    const driver = dbService.createDriver({
      name,
      vehicleType,
      vehicleNumber,
      rating: 5.0, // Note par défaut
      totalTrips: 0,
      isAvailable: true,
      latitude: latitude || 0,
      longitude: longitude || 0
    });

    res.status(201).json({
      success: true,
      driverId: driver.id,
      message: 'Conducteur créé avec succès'
    });
  } catch (error) {
    console.error('Erreur lors de la création du conducteur:', error);
    res.status(500).json({
      success: false,
      message: `Erreur lors de la création du conducteur: ${error.message}`
    });
  }
});

// API pour récupérer les conducteurs disponibles
app.get('/api/drivers', (req, res) => {
  try {
    const { isAvailable } = req.query;
    const filters = {};

    if (isAvailable !== undefined) {
      filters.isAvailable = isAvailable === 'true';
    }

    const drivers = dbService.getDrivers(filters);

    res.json({
      success: true,
      drivers
    });
  } catch (error) {
    console.error('Erreur lors de la récupération des conducteurs:', error);
    res.status(500).json({
      success: false,
      message: `Erreur lors de la récupération des conducteurs: ${error.message}`
    });
  }
});

// API endpoints for AI service
app.get('/api/ai/health', async (req, res) => {
  try {
    const health = await aiService.checkHealth();
    res.json({
      success: true,
      status: health.status,
      message: 'AI service health check',
      details: health
    });
  } catch (error) {
    console.error('Error checking AI service health:', error);
    res.status(500).json({
      success: false,
      status: 'error',
      message: `Error checking AI service health: ${error.message}`
    });
  }
});

app.post('/api/ai/predict', async (req, res) => {
  try {
    const { originalDistance, distanceAfterAddingRider, newRiderDistance, contextData } = req.body;

    if (!originalDistance || !distanceAfterAddingRider || !newRiderDistance) {
      return res.status(400).json({
        success: false,
        message: 'Missing required parameters: originalDistance, distanceAfterAddingRider, newRiderDistance'
      });
    }

    const prediction = await aiService.predictRideSharing(
      originalDistance,
      distanceAfterAddingRider,
      newRiderDistance,
      contextData || {}
    );

    // Store prediction in database
    dbService.insertPredictionData({
      original_distance: originalDistance / 1000, // Convert to km
      distance_after_adding_rider: distanceAfterAddingRider / 1000,
      new_rider_distance: newRiderDistance / 1000,
      prediction: prediction.shouldAddRider,
      score: prediction.score,
      context: contextData || {}
    });

    res.json({
      success: true,
      prediction
    });
  } catch (error) {
    console.error('Error making AI prediction:', error);
    res.status(500).json({
      success: false,
      message: `Error making AI prediction: ${error.message}`
    });
  }
});

app.get('/api/ai/predictions', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 100;
    const predictions = dbService.getPredictionData(limit);

    res.json({
      success: true,
      count: predictions.length,
      predictions
    });
  } catch (error) {
    console.error('Error retrieving AI predictions:', error);
    res.status(500).json({
      success: false,
      message: `Error retrieving AI predictions: ${error.message}`
    });
  }
});

app.post('/api/rides/:rideId/ai-prediction', async (req, res) => {
  try {
    const { rideId } = req.params;
    const { predictionData } = req.body;

    if (!predictionData) {
      return res.status(400).json({
        success: false,
        message: 'Missing required parameter: predictionData'
      });
    }

    const ride = dbService.getRideById(rideId);
    if (!ride) {
      return res.status(404).json({
        success: false,
        message: `Ride not found: ${rideId}`
      });
    }

    const updatedRide = dbService.updateRideWithAIPrediction(rideId, predictionData);

    res.json({
      success: true,
      ride: updatedRide
    });
  } catch (error) {
    console.error('Error updating ride with AI prediction:', error);
    res.status(500).json({
      success: false,
      message: `Error updating ride with AI prediction: ${error.message}`
    });
  }
});

// تشغيل الخادم
server.listen(PORT, () => {
  console.log(`الخادم يعمل على المنفذ ${PORT}`);
});
