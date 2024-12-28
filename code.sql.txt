-- Creating new database 
CREATE database db2;
USE db2;


-- Creating the users table to manage users interacting with models
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    role ENUM('data_scientist', 'engineer', 'admin') DEFAULT 'data_scientist',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Creating the models table to store model metadata
CREATE TABLE models (
    model_id INT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(255) NOT NULL,
    model_type VARCHAR(255) NOT NULL,  -- E.g., "RandomForest", "Neural Network"
    framework VARCHAR(255) NOT NULL,  -- E.g., "TensorFlow", "PyTorch", "scikit-learn"
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,  -- Whether the model is currently in use
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,  -- Foreign key referencing users
    FOREIGN KEY (created_by) REFERENCES users(user_id)
);

-- Indexing model_name for faster search
CREATE INDEX idx_model_name ON models(model_name);

-- Creating the model_versions table to manage versioning of models
CREATE TABLE model_versions (
    version_id INT AUTO_INCREMENT PRIMARY KEY,
    model_id INT,
    version_number VARCHAR(50) NOT NULL,  -- E.g., "v1.0", "v2.1"
    file_path VARCHAR(255) NOT NULL,  -- Path to the model file
    trained_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (model_id) REFERENCES models(model_id)
);

-- Creating the datasets table for datasets used in training/testing
CREATE TABLE datasets (
    dataset_id INT AUTO_INCREMENT PRIMARY KEY,
    dataset_name VARCHAR(255) NOT NULL,
    dataset_type ENUM('train', 'test', 'validation') NOT NULL,  -- Type of dataset
    source VARCHAR(255),  -- Source of dataset, e.g., "Kaggle"
    description TEXT,
    size INT,  -- Number of rows
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Creating the metrics table for storing evaluation metrics of model versions
CREATE TABLE metrics (
    metric_id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT,
    accuracy DECIMAL(5, 4),  -- Accuracy score (0.0000 to 1.0000)
    `precision` DECIMAL(5, 4),
    recall DECIMAL(5, 4),
    f1_score DECIMAL(5, 4),
    auc DECIMAL(5, 4),
    rmse DECIMAL(10, 6),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (version_id) REFERENCES model_versions(version_id)
);

-- Creating the model_parameters table for hyperparameters used in training
CREATE TABLE model_parameters (
    parameter_id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT,
    parameter_name VARCHAR(255),  -- Name of the hyperparameter (e.g., "learning_rate")
    parameter_value VARCHAR(255),  -- Value of the hyperparameter (e.g., "0.01")
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (version_id) REFERENCES model_versions(version_id)
);

-- Creating the training_runs table for logging model training sessions
CREATE TABLE training_runs (
    run_id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    duration INT,  -- Duration of training in seconds
    hardware VARCHAR(255),  -- Hardware used for training (e.g., "GPU", "CPU")
    status ENUM('completed', 'failed', 'interrupted') DEFAULT 'completed',
    log_file_path VARCHAR(255),  -- Path to the training log file
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (version_id) REFERENCES model_versions(version_id)
);

-- Creating the deployments table for tracking model deployments
CREATE TABLE deployments (
    deployment_id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT,
    deployment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    environment ENUM('production', 'staging', 'testing') DEFAULT 'production',  -- Deployment environment
    status ENUM('deployed', 'failed') DEFAULT 'deployed',  -- Deployment status
    model_url VARCHAR(255),  -- URL to access the deployed model
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (version_id) REFERENCES model_versions(version_id)
);

-- Adding indexes on frequently queried fields for performance
CREATE INDEX idx_version_number ON model_versions(version_number);
CREATE INDEX idx_dataset_type ON datasets(dataset_type);
CREATE INDEX idx_metric_version ON metrics(version_id);

-- Sample query to insert a new model with its first version and metrics
INSERT INTO models (model_name, model_type, framework, description, created_by)
VALUES ('RandomForestClassifier', 'RandomForest', 'scikit-learn', 'Random forest model for classification tasks.', 1);

-- Get the ID of the newly inserted model (using LAST_INSERT_ID() for example purposes)
SET @model_id = LAST_INSERT_ID();

-- Inserting the first version of the model
INSERT INTO model_versions (model_id, version_number, file_path, description)
VALUES (@model_id, 'v1.0', '/models/random_forest_v1.pkl', 'Initial version of the random forest classifier.');

-- Get the version ID of the inserted version
SET @version_id = LAST_INSERT_ID();

-- Insert some evaluation metrics for this version
INSERT INTO metrics (version_id, accuracy, `precision`, recall, f1_score, auc, rmse)
VALUES (@version_id, 0.95, 0.92, 0.91, 0.93, 0.98, 0.12);

-- Insert hyperparameters for the model version
INSERT INTO model_parameters (version_id, parameter_name, parameter_value)
VALUES (@version_id, 'n_estimators', '100'),
       (@version_id, 'max_depth', '10'),
       (@version_id, 'min_samples_split', '2');

-- Log a training run
INSERT INTO training_runs (version_id, start_time, end_time, duration, hardware, status, log_file_path)
VALUES (@version_id, NOW(), NOW() + INTERVAL 1 HOUR, 3600, 'GPU', 'completed', '/logs/train_log.txt');
