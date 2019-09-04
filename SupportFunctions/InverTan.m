function ango = InverTan(x,y)
%  given an x and y position, returns the angle to that location

       if (x >= 0)
         ango = atan(y/x);
       else
          if (x == 0)
              if (y > 0)
                  ango = (pi/2);
              else
                  ango = -(pi/2);
              end
          else
              if (y > 0)
                  ango = atan(y/x) + pi;
              else
                  ango = atan(y/x) - pi;
              end
          end
       end
end
       