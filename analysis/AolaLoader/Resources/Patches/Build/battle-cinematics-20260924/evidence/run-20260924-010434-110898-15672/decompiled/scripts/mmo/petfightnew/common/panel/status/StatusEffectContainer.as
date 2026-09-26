package mmo.petfightnew.common.panel.status
{
   import com.adobe.utils.StringUtil;
   import flash.display.Sprite;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.StatusUtil;
   
   public class StatusEffectContainer extends Sprite
   {
      
      private var _gameOptionSvr:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
      
      private var _list:Array = [];
      
      private var _isAtBack:Boolean = true;
      
      public function StatusEffectContainer()
      {
         super();
      }
      
      public function update(param1:Array) : void
      {
         var _loc6_:StatusEffect = null;
         var _loc7_:String = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:Object = null;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:Boolean = false;
         var _loc5_:int = 0;
         for(; _loc5_ < param1.length || _loc2_ < this._list.length; _loc5_++)
         {
            _loc6_ = this._list[_loc2_];
            if(_loc5_ < param1.length)
            {
               _loc7_ = param1[_loc5_];
               _loc8_ = -1;
               _loc9_ = -1;
               for each(_loc10_ in StatusUtil.SpecialStatusArr)
               {
                  if(_loc7_.indexOf(_loc10_.preStr) == 0)
                  {
                     if(_loc10_.frame)
                     {
                        _loc8_ = int(_loc10_.frame);
                     }
                     else
                     {
                        _loc8_ = StatusUtil.getCommonBuffSpcialStatusFrame(_loc7_,_loc10_.startFrame);
                     }
                     if(_loc10_.scale)
                     {
                        _loc9_ = int(_loc10_.scale);
                     }
                     this._isAtBack = false;
                     _loc4_ = true;
                     break;
                  }
               }
               if(_loc8_ == -1)
               {
                  if(!this.isTargetStatus(_loc7_))
                  {
                     continue;
                  }
                  _loc8_ = StatusUtil.getFrame(_loc7_);
                  if(StatusUtil.SpecialStatusFrameArr.indexOf(_loc8_) == -1)
                  {
                     continue;
                  }
               }
               if(_loc8_ > 0)
               {
                  if(_loc2_ == 0 && this._isAtBack)
                  {
                     this._isAtBack = !StatusUtil.isUpView(_loc7_);
                  }
                  if(_loc6_ == null)
                  {
                     this._list[_loc2_] = _loc6_ = FightMcPool.instance.getRes(StatusEffect,true);
                     if(_loc9_ == -1)
                     {
                        _loc6_.scaleX = _loc6_.scaleY = FightData.instance.teamScale;
                     }
                     else
                     {
                        _loc6_.scaleX = _loc6_.scaleY = _loc9_;
                     }
                  }
                  _loc6_.gotoAndStop(_loc8_);
                  if(!this.contains(_loc6_))
                  {
                     this.addChild(_loc6_);
                  }
                  if(_loc4_)
                  {
                     _loc6_.y = _loc3_;
                     _loc3_ -= 25;
                  }
                  _loc2_++;
               }
            }
            else if(_loc6_ != null)
            {
               FightMcPool.instance.recycle(_loc6_,StatusEffect);
               this._list[_loc2_] = null;
               _loc2_++;
            }
            else
            {
               _loc2_++;
            }
         }
      }
      
      private function isTargetStatus(param1:String) : Boolean
      {
         if(StringUtil.isNullOrEmpty(param1))
         {
            return false;
         }
         if(StatusUtil.noMovieStatusArr.indexOf(param1) == -1 || StatusUtil.isLegendFieldStatus(param1) || StatusUtil.isDegeneratorXianStatus(param1))
         {
            return false;
         }
         return true;
      }
      
      public function isAtBack() : Boolean
      {
         return this._isAtBack;
      }
      
      public function dispose() : void
      {
         this._list = null;
      }
   }
}

