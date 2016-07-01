function [ H ] = refineHomography( ok,X1,X2,H )
%REFINEHOMOGRAPHY Summary of this function goes here
%   Detailed explanation goes here
residual = residualFact(ok,X1,X2);


if exist('fminsearch') == 2
  H = H / H(3,3) ;
  
  opts = optimset('Display', 'none', 'TolFun', 1e-8, 'TolX', 1e-8) ;
  H(1:8) = fminsearch(residual, H(1:8)', opts) ;
else
  warning('Refinement disabled as fminsearch was not found.') ;
end

end

