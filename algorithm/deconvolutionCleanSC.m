function Q = deconvolutionCleanSC(D, e, w)

[numberOfScanningPointsY, numberOfScanningPointsX, nSensors] = size(e);
maxIterations = 100;


%Safety factor 0 < loopGain < 1
loopGain = 0.9;

%Initialise cross spectral matrix (CSM)
D(logical(eye(nSensors))) = 0;

%Initialise final clean image
Q = zeros(numberOfScanningPointsY, numberOfScanningPointsX);

%Initialise break criterion
sumOfCSM = sum(sum(abs(D)));
sumOfDegradedCSM = sumOfCSM;


for cleanMapIterations = 1:maxIterations
    
    % -------------------------------------------------------
    % 1. Calculate dirty map
    P = zeros(numberOfScanningPointsY, numberOfScanningPointsX);
    for scanningPointY = 1:numberOfScanningPointsY
        for scanningPointX = 1:numberOfScanningPointsX
            ee = reshape(e(scanningPointY, scanningPointX, :), nSensors, 1);
            P(scanningPointY, scanningPointX) = (w.*ee')*D*(ee.*w');
        end
    end
    
    
    
    % -------------------------------------------------------
    % 2. Find peak value and its position in dirty map
    [maxPeakValue, maxPeakIndx] = max(P(:));
    [maxPeakValueYIndx, maxPeakValueXIndx] = ind2sub(size(P), maxPeakIndx);
    
    
    
    % -------------------------------------------------------
    % 3. Calculate the CSM induced by the peak source
    
    % Steering vector to location of peak source
    g = reshape(e(maxPeakValueYIndx, maxPeakValueXIndx, :), nSensors, 1);
    
    %Get value of source component, initialise h as gmax
    h = g;
    for iterH = 1:maxIterations
        hOld = h;
        H = h*h';
        
        H(~logical(eye(nSensors))) = 0;
        h = 1/sqrt(1+(w.*g')*H*(g.*w'))*(D*(g.*w')/maxPeakValue + H*(g.*w'));
        if norm(h-hOld) < 1e-6
            break;
        end
    end
    
    
    
    % -------------------------------------------------------
    % 4. New updated map with clean beam from peak source location
    % Clean beam with specified width and max value of 1
    PmaxCleanBeam = zeros(numberOfScanningPointsY, numberOfScanningPointsX);
    PmaxCleanBeam(maxPeakValueYIndx, maxPeakValueXIndx) = 1;
    
    % Update clean map with clean beam from peak source location
    Q = Q + loopGain*maxPeakValue*PmaxCleanBeam;
    
    
    
    % -------------------------------------------------------
    % 5. Calculate degraded cross spectral matrix
    D = D - loopGain*maxPeakValue*(h*h');
    D(logical(eye(nSensors))) = 0;
    
    % Stop the iteration if the degraded CSM contains more information than
    % in the previous iteration
    sumOfCSM = sum(sum(abs(D)));
    if sumOfCSM > sumOfDegradedCSM
        disp(['Converged after ' num2str(cleanMapIterations) ' iterations'])
        break;
    end
    sumOfDegradedCSM = sumOfCSM;
    
    
end

% 6. Source plot is written as summation of clean beams and remaining dirty map
Q = Q + P;



end