index = 1;

mu      = 100;
sigma   = 100;
upper   = 200;
lower   = 1;
while index < 100000
    n_rand = normrnd(mu,sigma,1,1);
    while  n_rand < lower || n_rand > upper
        n_rand = normrnd(mu,sigma,1,1);
    end
    vals(index) = n_rand;
    index = index+1;
end
subplot(2,1,1)
plot(vals)
subplot(2,1,2)
hist(vals,100)