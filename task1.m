fx = createSurrogate('NACA0012', true)
fx_extended = createSurrogate('NACA0012', true, -20:1:35)

alpha1 = -10:1:10
alpha = -20:1:35

[CL, CD] = fx(alpha/ (180/pi))
[CL_extended, CD_extended] = fx_extended(alpha/ (180/pi))
colours = 'rgbcmyk';
subplot(2,2,1)
plot(alpha, CL, 'Color', colours(2), DisplayName="NACA0012");

subplot(2,2,2)
plot(alpha, CD, 'Color', colours(2), DisplayName="NACA0012");

subplot(2,2,3)
plot(alpha, CL_extended, 'Color', colours(2), DisplayName="NACA0012");

subplot(2,2,4)
plot(alpha, CD_extended, 'Color', colours(2), DisplayName="NACA0012");