 
CREATE database db2;
USE db2;

CREATE TABLE users
    (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    role ENUM('data_scientist', 'engineer', 'admin') DEFAULT 'data_scientist',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE models 
    (
    model_id INT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(255) NOT NULL,
    model_type VARCHAR(255) NOT NULL, 
    framework VARCHAR(255) NOT NULL,  
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,  
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by INT,  
    FOREIGN KEY (created_by) REFERENCES users(user_id)
);

CREATE INDEX idx_model_name ON models(model_name);

CREATE TABLE model_versions 
    (
    version_id INT AUTO_INCREMENT PRIMARY KEY,
    model_id INT,
    version_number VARCHAR(50) NOT NULL, 
    file_path VARCHAR(255) NOT NULL,  
    trained_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (model_id) REFERENCES models(model_id)
);

CREATE TABLE datasets 
    (
    dataset_id INT AUTO_INCREMENT PRIMARY KEY,
    dataset_name VARCHAR(255) NOT NULL,
    dataset_type ENUM('train', 'test', 'validation') NOT NULL,  
    source VARCHAR(255), 
    description TEXT,
    size INT, 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE metrics 
    (
    metric_id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT,
    accuracy DECIMAL(5, 4),  
    `precision` DECIMAL(5, 4),
    recall DECIMAL(5, 4),
    f1_score DECIMAL(5, 4),
    auc DECIMAL(5, 4),
    rmse DECIMAL(10, 6),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (version_id) REFERENCES model_versions(version_id)
);

CREATE TABLE model_parameters
    (
    parameter_id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT,
    parameter_name VARCHAR(255),  
    parameter_value VARCHAR(255),  
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (version_id) REFERENCES model_versions(version_id)
);
CREATE TABLE training_runs 
    (
    run_id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    duration INT,  
    hardware VARCHAR(255),  
    status ENUM('completed', 'failed', 'interrupted') DEFAULT 'completed',
    log_file_path VARCHAR(255),  
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (version_id) REFERENCES model_versions(version_id)
);

CREATE TABLE deployments 
    (
    deployment_id INT AUTO_INCREMENT PRIMARY KEY,
    version_id INT,
    deployment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    environment ENUM('production', 'staging', 'testing') DEFAULT 'production',  
    status ENUM('deployed', 'failed') DEFAULT 'deployed', 
    model_url VARCHAR(255),  
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (version_id) REFERENCES model_versions(version_id)
);

CREATE INDEX idx_version_number ON model_versions(version_number);
CREATE INDEX idx_dataset_type ON datasets(dataset_type);
CREATE INDEX idx_metric_version ON metrics(version_id);

INSERT INTO models (model_name, model_type, framework, description, created_by)
VALUES ('RandomForestClassifier', 'RandomForest', 'scikit-learn', 'Random forest model for classification tasks.', 1);

SET @model_id = LAST_INSERT_ID();

INSERT INTO model_versions (model_id, version_number, file_path, description)
VALUES (@model_id, 'v1.0', '/models/random_forest_v1.pkl', 'Initial version of the random forest classifier.');

SET @version_id = LAST_INSERT_ID();

INSERT INTO metrics (version_id, accuracy, `precision`, recall, f1_score, auc, rmse)
VALUES (@version_id, 0.95, 0.92, 0.91, 0.93, 0.98, 0.12);

INSERT INTO model_parameters (version_id, parameter_name, parameter_value)
VALUES (@version_id, 'n_estimators', '100'),
       (@version_id, 'max_depth', '10'),
       (@version_id, 'min_samples_split', '2');

INSERT INTO training_runs (version_id, start_time, end_time, duration, hardware, status, log_file_path)
VALUES (@version_id, NOW(), NOW() + INTERVAL 1 HOUR, 3600, 'GPU', 'completed', '/logs/train_log.txt');
