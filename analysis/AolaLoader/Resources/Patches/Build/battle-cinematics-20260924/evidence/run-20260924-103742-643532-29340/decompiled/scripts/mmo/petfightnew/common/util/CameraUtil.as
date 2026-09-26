package mmo.petfightnew.common.util
{
   import flash.display.MovieClip;
   import flash.geom.Point;
   import mmo.common.event.EnterFrameManager;
   import mmo.common.simplemoviehelper.PlayTopMovieHelper;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.MCPetContainer;
   
   public class CameraUtil
   {
      
      private static const ScaleCoefficient:Number = 0.004;
      
      private static const MaxTimes:int = 60;
      
      public function CameraUtil()
      {
         super();
      }
      
      public static function changeScaleByPet(param1:MCPetContainer, param2:FightPanel, param3:MovieClip, param4:Function) : void
      {
         var times:int = 0;
         var originPoint:Point = null;
         var offsetX:Number = NaN;
         var offsetY:Number = NaN;
         var changeScale:Function = null;
         var target:MCPetContainer = param1;
         var fightPanel:FightPanel = param2;
         var spiritMv:MovieClip = param3;
         var callBack:Function = param4;
         changeScale = function():void
         {
            ++times;
            if(times <= 20)
            {
               fightPanel.layerPlatform.scaleX += ScaleCoefficient * times;
               fightPanel.layerPlatform.scaleY += ScaleCoefficient * times;
               fightPanel.layerPet.scaleX += ScaleCoefficient * times;
               fightPanel.layerPet.scaleY += ScaleCoefficient * times;
               fightPanel.layerBackground.scaleX += ScaleCoefficient / 2 * times;
               fightPanel.layerBackground.scaleY += ScaleCoefficient / 2 * times;
               fightPanel.layerPlatform.x = -originPoint.x * (fightPanel.layerPlatform.scaleX - 1) + offsetX * times;
               fightPanel.layerPlatform.y = -originPoint.y * (fightPanel.layerPlatform.scaleY - 1) + offsetY * times;
               fightPanel.layerPet.x = -originPoint.x * (fightPanel.layerPet.scaleX - 1) + offsetX * times;
               fightPanel.layerPet.y = -originPoint.y * (fightPanel.layerPet.scaleY - 1) + offsetY * times;
               fightPanel.layerBackground.x = -(fightPanel.layerBackground.scaleX - 1) * 960 / 2;
               fightPanel.layerBackground.y = -(fightPanel.layerBackground.scaleY - 1) * 560 / 2;
            }
            else if(times == 21)
            {
               new PlayTopMovieHelper().playMovie(spiritMv);
            }
            else if(times > 40)
            {
               if(times <= MaxTimes)
               {
                  fightPanel.layerPlatform.scaleX -= ScaleCoefficient * (times - 40);
                  fightPanel.layerPlatform.scaleY -= ScaleCoefficient * (times - 40);
                  fightPanel.layerPet.scaleX -= ScaleCoefficient * (times - 40);
                  fightPanel.layerPet.scaleY -= ScaleCoefficient * (times - 40);
                  fightPanel.layerBackground.scaleX -= ScaleCoefficient / 2 * (times - 40);
                  fightPanel.layerBackground.scaleY -= ScaleCoefficient / 2 * (times - 40);
                  fightPanel.layerPlatform.x = -originPoint.x * (fightPanel.layerPlatform.scaleX - 1) + offsetX * (MaxTimes - times);
                  fightPanel.layerPlatform.y = -originPoint.y * (fightPanel.layerPlatform.scaleY - 1) + offsetY * (MaxTimes - times);
                  fightPanel.layerPet.x = -originPoint.x * (fightPanel.layerPet.scaleX - 1) + offsetX * (MaxTimes - times);
                  fightPanel.layerPet.y = -originPoint.y * (fightPanel.layerPet.scaleY - 1) + offsetY * (MaxTimes - times);
                  fightPanel.layerBackground.x = -(fightPanel.layerBackground.scaleX - 1) * 960 / 2;
                  fightPanel.layerBackground.y = -(fightPanel.layerBackground.scaleY - 1) * 560 / 2;
               }
               else
               {
                  if(target == null)
                  {
                     return;
                  }
                  EnterFrameManager.instance.remove(changeScale);
                  fightPanel.layerPlatform.scaleX = 1;
                  fightPanel.layerPlatform.scaleY = 1;
                  fightPanel.layerPet.scaleX = 1;
                  fightPanel.layerPet.scaleY = 1;
                  fightPanel.layerBackground.scaleX = 1;
                  fightPanel.layerBackground.scaleY = 1;
                  fightPanel.layerPlatform.x = 0;
                  fightPanel.layerPlatform.y = 0;
                  fightPanel.layerPet.x = 0;
                  fightPanel.layerPet.y = 0;
                  fightPanel.layerBackground.x = 0;
                  fightPanel.layerBackground.y = 0;
                  if(callBack != null)
                  {
                     callBack.apply();
                  }
               }
            }
         };
         times = 0;
         originPoint = new Point(target.x,target.y);
         offsetX = (480 - target.x) / MaxTimes;
         offsetY = (460 - target.y) / MaxTimes;
         EnterFrameManager.instance.register(changeScale,null,1);
      }
      
      public static function changeScaleByHuanLingShiPet(param1:MCPetContainer, param2:FightPanel, param3:MovieClip, param4:Function) : void
      {
         var times:int = 0;
         var originPoint:Point = null;
         var offsetX:Number = NaN;
         var offsetY:Number = NaN;
         var scaleCoefficient:Number = NaN;
         var changeScale:Function = null;
         var target:MCPetContainer = param1;
         var fightPanel:FightPanel = param2;
         var spiritMv:MovieClip = param3;
         var callBack:Function = param4;
         changeScale = function():void
         {
            ++times;
            if(times <= 20)
            {
               fightPanel.layerPlatform.scaleX -= scaleCoefficient;
               fightPanel.layerPlatform.scaleY -= scaleCoefficient;
               fightPanel.layerPet.scaleX -= scaleCoefficient;
               fightPanel.layerPet.scaleY -= scaleCoefficient;
               fightPanel.layerPlatform.x = -originPoint.x * (fightPanel.layerPlatform.scaleX - 1) + offsetX * times;
               fightPanel.layerPlatform.y = -originPoint.y * (fightPanel.layerPlatform.scaleY - 1) + offsetY * times;
               fightPanel.layerPet.x = -originPoint.x * (fightPanel.layerPet.scaleX - 1) + offsetX * times;
               fightPanel.layerPet.y = -originPoint.y * (fightPanel.layerPet.scaleY - 1) + offsetY * times;
            }
            else if(times == 21)
            {
               new PlayTopMovieHelper().playMovie(spiritMv);
            }
            else if(times > 40)
            {
               if(times <= MaxTimes)
               {
                  fightPanel.layerPlatform.scaleX += scaleCoefficient;
                  fightPanel.layerPlatform.scaleY += scaleCoefficient;
                  fightPanel.layerPet.scaleX += scaleCoefficient;
                  fightPanel.layerPet.scaleY += scaleCoefficient;
                  fightPanel.layerPlatform.x = -originPoint.x * (fightPanel.layerPlatform.scaleX - 1) + offsetX * (MaxTimes - times);
                  fightPanel.layerPlatform.y = -originPoint.y * (fightPanel.layerPlatform.scaleY - 1) + offsetY * (MaxTimes - times);
                  fightPanel.layerPet.x = -originPoint.x * (fightPanel.layerPet.scaleX - 1) + offsetX * (MaxTimes - times);
                  fightPanel.layerPet.y = -originPoint.y * (fightPanel.layerPet.scaleY - 1) + offsetY * (MaxTimes - times);
               }
               else
               {
                  if(target == null)
                  {
                     return;
                  }
                  EnterFrameManager.instance.remove(changeScale);
                  fightPanel.layerPlatform.scaleX = 1;
                  fightPanel.layerPlatform.scaleY = 1;
                  fightPanel.layerPet.scaleX = 1;
                  fightPanel.layerPet.scaleY = 1;
                  fightPanel.layerBackground.scaleX = 1;
                  fightPanel.layerBackground.scaleY = 1;
                  fightPanel.layerPlatform.x = 0;
                  fightPanel.layerPlatform.y = 0;
                  fightPanel.layerPet.x = 0;
                  fightPanel.layerPet.y = 0;
                  fightPanel.layerBackground.x = 0;
                  fightPanel.layerBackground.y = 0;
                  if(callBack != null)
                  {
                     callBack.apply();
                  }
               }
            }
         };
         times = 0;
         originPoint = new Point(target.x,target.y);
         offsetX = (480 - target.x) / MaxTimes;
         offsetY = (460 - target.y) / MaxTimes;
         EnterFrameManager.instance.register(changeScale,null,1);
         scaleCoefficient = ScaleCoefficient * 5;
      }
   }
}

