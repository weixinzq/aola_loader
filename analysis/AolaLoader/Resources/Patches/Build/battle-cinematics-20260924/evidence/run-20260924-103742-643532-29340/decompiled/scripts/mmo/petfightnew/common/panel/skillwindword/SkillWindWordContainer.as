package mmo.petfightnew.common.panel.skillwindword
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.FightMcPool;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.actthings.helper.ActMovieHelper;
   
   public class SkillWindWordContainer extends Sprite
   {
      
      private var _gameOptionSvr:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
      
      public function SkillWindWordContainer()
      {
         super();
      }
      
      public function update(param1:Array) : void
      {
         var _loc2_:Array = null;
         var _loc3_:Object = null;
         var _loc4_:SkillWindWordMc = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         if(!this._gameOptionSvr.isFightBuffTips)
         {
            return;
         }
         if(Boolean(param1) && param1.length > 0)
         {
            _loc2_ = [];
            for each(_loc3_ in param1)
            {
               _loc5_ = _loc3_.bid == null ? -1 : int(_loc3_.bid);
               _loc6_ = _loc3_.nid == null ? -1 : int(_loc3_.nid);
               _loc7_ = 0;
               while(_loc7_ < StatusUtil.SkillWindWordArr.length)
               {
                  if(StatusUtil.SkillWindWordArr[_loc7_]["effectId"] == _loc5_ || StatusUtil.SkillWindWordArr[_loc7_]["effectId"] == _loc6_)
                  {
                     _loc2_.push(StatusUtil.SkillWindWordArr[_loc7_]["frame"]);
                     break;
                  }
                  _loc7_++;
               }
            }
            _loc4_ = FightMcPool.instance.getRes(SkillWindWordMc,true);
            _loc4_.scaleX = _loc4_.scaleY = FightData.instance.teamScale;
            if(!this.contains(_loc4_))
            {
               this.addChild(_loc4_);
            }
            this.playStatusEff(_loc2_,_loc4_.mc);
         }
      }
      
      private function playStatusEff(param1:Array, param2:MovieClip) : void
      {
         var frameId:int = 0;
         var skillWindWordFrameList:Array = param1;
         var mcSkillWindWord:MovieClip = param2;
         if(skillWindWordFrameList.length > 0 && mcSkillWindWord && Boolean(mcSkillWindWord.parent))
         {
            frameId = int(skillWindWordFrameList.pop());
            mcSkillWindWord.gotoAndStop(frameId);
            ActMovieHelper.playMcMv(mcSkillWindWord.mc,function():void
            {
               playStatusEff(skillWindWordFrameList,mcSkillWindWord);
            });
         }
         else
         {
            FightMcPool.instance.recycle(mcSkillWindWord.parent,SkillWindWordMc);
         }
      }
   }
}

