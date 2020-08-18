function [ output_args ] = fft_test( input_args )

   Fs = 1000;                      % samples per second
   dt = 1/Fs;                     % seconds per sample
   StopTime = 1;                  % seconds
   t = (0:dt:StopTime-dt)';
   N = size(t,1);
   
   %% Sine wave:
   Fc = 12;                       % hertz
   x = cos(2*pi*Fc*t) + rand(N,1) - .5;
  
   %% Fourier Transform:
   X = fftshift(fft(x));
   
   %% Frequency specifications:
   dF   = Fs/N;                      % hertz
   f    = -Fs/2:dF:Fs/2-dF;           % hertz
   psd  = abs(X)/N;
   
   figure;
   
    s = find(f > 200,1)
    e = find(f > 250,1) - 1
    
   plot(f(s:e),psd(s:e));
   
   xlabel('Frequency (in hertz)');
   title('Magnitude Response');
   
   
end

