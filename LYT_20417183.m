%Yutong Liu
%sqyyl4@nottingham.edu.cn

%% PRELIMINARY TASK - ARDUINO AND GIT INSTALLATION [10 MARKS]

% Establish communication with Arduino
arduino_board = arduino('COM3', 'Uno');

% Define the LED pins
greenLed = 'D2';
yellowLed = 'D3';
redLed = 'D4';

% Turn all LEDs off initially
writeDigitalPin(arduino_board, greenLed, 0);
writeDigitalPin(arduino_board, yellowLed, 0);
writeDigitalPin(arduino_board, redLed, 0);

% Define the sensor pin
sensorPin = 'A0';

% Define LED loop blink
for i = 1:10 
    writeDigitalPin(arduino_board, ledPin, 1); % Turn LED on
    pause(0.5); % The interval is 0.5 seconds
    writeDigitalPin(arduino_board, ledPin, 0); % Turn LED off
    pause(0.5); % The interval is 0.5 seconds
end

%% TASK 1 – READ TEMPERATURE DATA, CONTROL LEDs, AND WRITE TO A LOG FILE [20 MARKS] 

% Data acquisition loop setup
duration = 600; 
timeInterval = 1; 
numReadings = duration / timeInterval; 
temperatureData = zeros(1, numReadings); 
timeData = 0:timeInterval:(duration - timeInterval);

% Start the data acquisition and control loop
for i = 1:numReadings
    voltage = readVoltage(arduino_board, sensorPin);
    temperature = voltageToTemperature(voltage); 
    temperatureData(i) = temperature; 
    
    % Control LEDs based on temperature
    if (Tem(i)>=18) && (Tem(i)<=24)
        writeDigitalPin(arduino_board, greenLed, 1); 
        writeDigitalPin(arduino_board, yellowLed, 0);
        writeDigitalPin(arduino_board, redLed, 0);
    elseif temperature < 18
        writeDigitalPin(arduino_board, yellowLed, 1); 
    else % when temperature > 24
        writeDigitalPin(arduino_board, redLed, 1);
    end
    
    pause(timeInterval); 
end

% Turn off all LEDs after the data acquisition loop
writeDigitalPin(arduino_board, greenLed, 0);
writeDigitalPin(arduino_board, yellowLed, 0);
writeDigitalPin(arduino_board, redLed, 0);

% Plotting the figure
figure;
plot(timeData, temperatureData);
xlabel('Time (seconds)');
ylabel('Temperature (°C)');
title('Cabin Temperature Over Time');

% Calculate statistics
Max=sprintf('%.2f',max(Tem));
Min=sprintf('%.2f',min(Tem));
Avg=sprintf('%.2f',mean(Tem));
fprintf('Data logging terminated');

% Convert timeData from seconds to minutes for logging purposes
timeDataMinutes = timeData / 60;

% Open the file
fileID = fopen('cabin_temperature_log.txt', 'w');

% Write the header information
disp('Table 1 - Output to screen formatting example\n');
datafprintf('Data logging initiated - %s\n', datestr(now, 'dd/mm/yyyy HH:MM:SS'));
locationfprintf(fileID, 'Location - Nottingham\n\n');

% Write the data in a formatted table
fprintf(fileID, 'Minute\tTemperature (°C)\n');

for i = 1:numReadings
    if mod(timeData(i), 60)==0
        fprintf(fileID, '%.2f\t%.2f\n', timeDataMinutes(i), temperatureData(i));
    end
end

fprintf(fileID, '\nMax temp\t%.2f °C\n', maxTemp);
fprintf(fileID, 'Min temp\t%.2f °C\n', minTemp);
fprintf(fileID, 'Average temp\t%.2f °C\n', avgTemp);
fprintf(fileID, '\nData logging terminated - %s\n', datestr(now, 'dd/mm/yyyy HH:MM:SS'));
fclose(fileID);

%% TASK 2 – LED TEMPERATURE MONITORING DEVICE IMPLEMENTATION [25 MARKS] 

function temp_monitor(arduino_board)
    % Define LED pins
    green_pin = 'D2';
    yellow_pin = 'D3';
    red_pin = 'D4';

    % Configure pins as digital outputs
    configurePin(arduino_board, green_pin, 'DigitalOutput');
    configurePin(arduino_board, yellow_pin, 'DigitalOutput');
    configurePin(arduino_board, red_pin, 'DigitalOutput');

    % Define temperature range
    lower_bound = 18;
    upper_bound = 24;

    % Create temperature graph
    figure;
    live_graph = animatedline;
    xlabel('Time');
    ylabel('Temperature (°C)');
    title('Live Temperature Data');
    grid on;

    % Monitoring loop
    while true
        temperature = readTemperature(arduino_board); 
        if isnumeric(temperature) && isscalar(temperature)
            addpoints(live_graph, datenum(datetime('now')), temperature);
        else
            error('Temperature must be a scalar numeric value.');
        end

        % Set the limits
        xlim([datenum(datetime('now')-minutes(1)), datenum(datetime('now'))]);
        ylim([lower_bound-5, upper_bound+5]);
        drawnow;

        % Control LEDs based on temperature
        if temperature >= lower_bound && temperature <= upper_bound
            writeDigitalPin(arduino_board, green_pin, 1);
            writeDigitalPin(arduino_board, yellow_pin, 0);
            writeDigitalPin(arduino_board, red_pin, 0);

        elseif temperature < lower_bound
            writeDigitalPin(arduino_board, green_pin, 0);
            blink_LED(arduino_board, yellow_pin, 0.5);
            writeDigitalPin(arduino_board, red_pin, 0);
            
        elseif temperature > upper_bound
            writeDigitalPin(arduino_board, green_pin, 0);
            writeDigitalPin(arduino_board, yellow_pin, 0);
            blink_LED(arduino_board, red_pin, 0.25);
        end
        pause(1);
    end
end

function blink_LED(arduino_board, pin, interval)
    writeDigitalPin(arduino_board, pin, 1); % Turn LED on
    pause(interval / 2);
    writeDigitalPin(arduino_board, pin, 0); % Turn LED off
    pause(interval / 2);
end

function temperature = readTemperature(arduino_board)
    sensor_value = readVoltage(arduino_board, 'A0'); 
    temperature = (sensor_value - 0.5) * 100; 
end

%% TASK 3 – ALGORITHMS – TEMPERATURE PREDICTION [25 MARKS] 

function temp_prediction(arduino_board)
    % Define the LED pins
    green_pin = 'D2';
    yellow_pin = 'D3';
    red_pin = 'D4';
 % Define sensor
 % sensor = 'A0';
 %  voltage = readVoltage(a, 'A0');   

    % Configure pins digital outputs
    configurePin(arduino_board, green_pin, 'DigitalOutput');
    configurePin(arduino_board, yellow_pin, 'DigitalOutput');
    configurePin(arduino_board, red_pin, 'DigitalOutput');

    % Define the initial temperature and time
    prev_temperature = readTemperature(arduino_board);
    prev_time = datetime('now');

    % Start the monitoring and prediction cycle loop
    while true
        current_temperature = readTemperature(arduino_board);
        current_time = datetime('now');
        time_diff = seconds(current_time - prev_time);
        if time_diff == 0
            Rateofchange = 0;
        else
            Rateofchange = (current_temperature - prev_temperature) / time_diff;
        end
        
        % Predict the temperature within 5 minutes
        predicted_temperature = current_temperature + Rateofchange * 300; 

        % Display the results
        fprintf('Current temperature: %.2f°C\n', current_temperature);
        fprintf('Rate of change: %.4f°C/s\n', Rateofchange);
        fprintf('Predicted temperature in 5 minutes: %.2f°C\n', predicted_temperature);

        % Determine which LED illuminate
        if abs(Rateofchange) <= 4/60
            writeDigitalPin(arduino_board, green_pin, 1);
            writeDigitalPin(arduino_board, yellow_pin, 0);
            writeDigitalPin(arduino_board, red_pin, 0);

        elseif Rateofchange > 4/60
            writeDigitalPin(arduino_board, green_pin, 0);
            writeDigitalPin(arduino_board, yellow_pin, 0);
            writeDigitalPin(arduino_board, red_pin, 1);

        elseif Rateofchange <- 4/60
            writeDigitalPin(arduino_board, green_pin, 0);
            writeDigitalPin(arduino_board, yellow_pin, 1);
            writeDigitalPin(arduino_board, red_pin, 0);
        end
    end
end


%% TASK 4 - REFLECTIVE STATEMENT [5 MARKS]
%The main challenge of this project is how to accurately measure temperature,
% as the data measured by the power supply and sensors may not be accurate 
% due to the noise generated by the connection circuit, and further calculations 
% are needed to make the data accurate.

% The main advantage of this project is that the ambient temperature can be 
% further adjusted by turning on the LED and observing the color changes of the LED lights.

% The limitation of this project may be that it is only tested on a small circuit 
% rather than a real experimental thermometer, and the model assumes a uniform rate 
% of change, which is not feasible in real-world situations. This may cause bias in the results.

% In the future, this project can design a machine that is suitable for actual 
% temperature changes and can predict future temperature changes for experimentation.
% This will improve the accuracy of the experiment



%% Define the function of changing voltage to tempreture 
function temperature = voltageToTemperature(voltage)
    temperature = (voltage - 0.5) * 100; 
end
