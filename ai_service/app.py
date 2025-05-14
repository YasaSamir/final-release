from flask import Flask, request, jsonify
import numpy as np
import pandas as pd
import joblib
import os
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, 
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Path to save the model
MODEL_PATH = 'ride_sharing_model.joblib'
SCALER_PATH = 'scaler.joblib'

# Initialize model and scaler
model = None
scaler = None

# Sample historical data for training (will be replaced with real data)
historical_data = pd.DataFrame({
    'original_distance': np.random.uniform(1, 20, 1000),  # km
    'distance_after_adding_rider': np.random.uniform(1, 30, 1000),  # km
    'new_rider_distance': np.random.uniform(1, 15, 1000),  # km
    'time_of_day': np.random.randint(0, 24, 1000),  # hour of day
    'day_of_week': np.random.randint(0, 7, 1000),  # 0=Monday, 6=Sunday
    'traffic_level': np.random.uniform(0, 1, 1000),  # 0=low, 1=high
    'weather_condition': np.random.randint(0, 5, 1000),  # 0=clear, 1=rain, 2=snow, etc.
})

# Generate target variable (beneficial or not)
historical_data['additional_distance'] = historical_data['distance_after_adding_rider'] - historical_data['original_distance']
historical_data['distance_ratio'] = historical_data['additional_distance'] / historical_data['new_rider_distance']
historical_data['is_beneficial'] = (historical_data['distance_ratio'] < 0.3) & (historical_data['new_rider_distance'] > 2)

def train_model():
    """Train the model with historical data"""
    global model, scaler
    
    logger.info("Training ride sharing prediction model...")
    
    # Features for training
    features = ['original_distance', 'distance_after_adding_rider', 'new_rider_distance', 
                'time_of_day', 'day_of_week', 'traffic_level', 'weather_condition']
    
    X = historical_data[features]
    y = historical_data['is_beneficial'].astype(int)
    
    # Scale features
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    # Train model
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_scaled, y)
    
    # Save model and scaler
    joblib.dump(model, MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)
    
    logger.info("Model trained and saved successfully")
    return model, scaler

def load_model():
    """Load the trained model if it exists, otherwise train a new one"""
    global model, scaler
    
    try:
        if os.path.exists(MODEL_PATH) and os.path.exists(SCALER_PATH):
            logger.info("Loading existing model and scaler...")
            model = joblib.load(MODEL_PATH)
            scaler = joblib.load(SCALER_PATH)
        else:
            logger.info("No existing model found. Training new model...")
            model, scaler = train_model()
    except Exception as e:
        logger.error(f"Error loading model: {e}")
        model, scaler = train_model()
    
    return model, scaler

@app.route('/predict', methods=['POST'])
def predict():
    """Predict if adding a new rider is beneficial"""
    try:
        # Get data from request
        data = request.json
        logger.info(f"Received prediction request: {data}")
        
        # Extract features
        original_distance = data.get('original_distance', 0)
        distance_after_adding_rider = data.get('distance_after_adding_rider', 0)
        new_rider_distance = data.get('new_rider_distance', 0)
        
        # Get additional context if available
        time_of_day = data.get('time_of_day', datetime.now().hour)
        day_of_week = data.get('day_of_week', datetime.now().weekday())
        traffic_level = data.get('traffic_level', 0.5)  # Default medium traffic
        weather_condition = data.get('weather_condition', 0)  # Default clear weather
        
        # Ensure model is loaded
        if model is None or scaler is None:
            load_model()
        
        # Prepare features
        features = np.array([[
            original_distance,
            distance_after_adding_rider,
            new_rider_distance,
            time_of_day,
            day_of_week,
            traffic_level,
            weather_condition
        ]])
        
        # Scale features
        features_scaled = scaler.transform(features)
        
        # Make prediction
        prediction = model.predict(features_scaled)[0]
        prediction_proba = model.predict_proba(features_scaled)[0][1]  # Probability of class 1
        
        # Calculate efficiency
        additional_distance = distance_after_adding_rider - original_distance
        distance_ratio = additional_distance / new_rider_distance if new_rider_distance > 0 else float('inf')
        efficiency = max(0, 100 - (distance_ratio * 100))
        
        # Calculate environmental impact
        co2_reduction = (new_rider_distance * 0.12)  # kg of CO2 saved (0.12 kg per km)
        fuel_saved = (new_rider_distance * 0.08)  # liters of fuel saved (0.08L per km)
        
        # Calculate fare details
        base_fare = 10  # Base fare in currency units
        per_km_rate = 2  # Rate per km in currency units
        
        original_fare = base_fare + (original_distance * per_km_rate)
        new_rider_direct_fare = base_fare + (new_rider_distance * per_km_rate)
        
        # Calculate fare split based on distance ratio
        original_rider_new_fare = original_fare * 0.7  # 30% discount for original rider
        new_rider_fare = base_fare * 0.5 + (new_rider_distance * per_km_rate * 0.8)  # 20% discount on distance
        
        original_rider_savings = original_fare - original_rider_new_fare
        new_rider_savings = new_rider_direct_fare - new_rider_fare
        total_savings = original_rider_savings + new_rider_savings
        
        # Prepare response
        response = {
            'prediction_score': float(prediction_proba),
            'add_rider': bool(prediction),
            'efficiency': round(efficiency),
            'fare_details': {
                'original_rider': {
                    'original_fare': round(original_fare),
                    'new_fare': round(original_rider_new_fare),
                    'savings': round(original_rider_savings)
                },
                'new_rider': {
                    'direct_fare': round(new_rider_direct_fare),
                    'shared_fare': round(new_rider_fare),
                    'savings': round(new_rider_savings)
                },
                'total_savings': round(total_savings)
            },
            'environmental_impact': {
                'co2_reduction': round(co2_reduction * 1000) / 1000,  # kg of CO2
                'fuel_saved': round(fuel_saved * 100) / 100  # liters
            }
        }
        
        logger.info(f"Prediction result: {response}")
        return jsonify(response)
    
    except Exception as e:
        logger.error(f"Error making prediction: {e}")
        return jsonify({
            'error': str(e),
            'message': 'Failed to make prediction'
        }), 500

@app.route('/train', methods=['POST'])
def train_endpoint():
    """Endpoint to retrain the model with new data"""
    try:
        # Get training data from request
        data = request.json
        logger.info(f"Received training request with {len(data)} records")
        
        # Convert to DataFrame
        new_data = pd.DataFrame(data)
        
        # Update historical data
        global historical_data
        historical_data = pd.concat([historical_data, new_data], ignore_index=True)
        
        # Train model
        train_model()
        
        return jsonify({
            'success': True,
            'message': 'Model trained successfully',
            'data_size': len(historical_data)
        })
    
    except Exception as e:
        logger.error(f"Error training model: {e}")
        return jsonify({
            'error': str(e),
            'message': 'Failed to train model'
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'scaler_loaded': scaler is not None
    })

if __name__ == '__main__':
    # Load model on startup
    from datetime import datetime
    load_model()
    
    # Run the app
    app.run(host='0.0.0.0', port=5000, debug=True)
