--[[
function Bresenhamline(from,to)
       local x0,y0 = from[1],from[2]
       local x1,y1 = to[1],to[2]
       local x,y,dx,dy,k,e
       local ret = {}
       dx = x1 - x0
       dy = y1 - y0
       e = 0-dx
       x = x0
       y = y0
       for i = 0,dx do
              table.insert(ret,{x,y})
              x = x + 1
              e = e + (2 * dy)
              if e > 0 then
                     y = y + 1
                     e = e - (2*dx)
              end
       end
       return ret
end
]]--

--[[
int CEnginApp::Draw_Line2(int x1,int y1,int x2, int y2,COLORREF color,UNINT *vb_start, int lpitch) 
{
    RECT cRect;
    //GetWindowRect(m_hwnd,&m_x2d_ClientRect);

    GetClientRect(m_hwnd, &cRect);
    ClientToScreen(m_hwnd, (LPPOINT)&cRect);
    ClientToScreen(m_hwnd, (LPPOINT)&cRect+1);

    vb_start = vb_start + cRect.left + cRect.top*lpitch;

    int dx = x2 - x1;
    int dy = y2 - y1;
    int ux = ((dx > 0) << 1) - 1;//x的增量方向，取或-1
    int uy = ((dy > 0) << 1) - 1;//y的增量方向，取或-1
    int x = x1, y = y1, eps;//eps为累加误差

    eps = 0;dx = abs(dx); dy = abs(dy); 
    if (dx > dy) 
    {
        for (x = x1; x != x2; x += ux)
        {
            Plot_Pixel_32(x,y,0,255,0,255,vb_start,lpitch);
            eps += dy;
            if ((eps << 1) >= dx)
            {
                y += uy; eps -= dx;
            }
        }
    }
    else
    {
        for (y = y1; y != y2; y += uy)
        {
            Plot_Pixel_32(x,y,0,255,0,255,vb_start,lpitch);
            eps += dx;
            if ((eps << 1) >= dy)
            {
                x += ux; eps -= dy;
            }
        }
    }      

    return 1;
}
]]--


function Bresenhamline(from,to)
       local x1,y1 = from[1],from[2]
       local x2,y2 = to[1],to[2]
       local dx = x2 - x1;
       local dy = y2 - y1;
       --int ux = ((dx > 0) << 1) - 1;//x的增量方向，取或-1
       --int uy = ((dy > 0) << 1) - 1;//y的增量方向，取或-1
       --int x = x1, y = y1, eps;//eps为累加误差 
       
       local ux
       if ux 

       local x,y,dps = x1,y1

end

