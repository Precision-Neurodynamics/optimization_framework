function [ output_args ] = test_gp_model( input_args )
%TEST_GP_MODEL Summary of this function goes here
%   Detailed explanation goes here
close all;
x = 0:.5:3;
y = sin(x) + rand(size(x))*.3;
gp_ = gp_model();

gp_.initialize_default(1)
gp_.x_data = x';
gp_.y_data = y';
t = (0:.01:3)';
[yp, ys] = gp_.predict(t);

ei = expected_improvement(t, max(gp_.y_data), gp_);

subplot(2,1,1)
hold on;
plot(t, yp, t, yp+ys, t, yp-ys)
plot(x, y, 'b.');

subplot(2,1,2)
plot(t,ei);
end

