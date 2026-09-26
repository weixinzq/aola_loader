package mmo.petfightnew.common.fightcontroller
{
   import com.greensock.TweenMax;
   import com.greensock.data.TweenLiteVars;
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.manager.FightMovieManager;
   import mmo.petfightnew.common.manager.FightTweenMaxManager;
   
   public class ChangeViewStatus
   {
      
      private static var _instance:ChangeViewStatus;
      
      private var fightPanel:FightPanel;
      
      public function ChangeViewStatus()
      {
         super();
      }
      
      public static function get instance() : ChangeViewStatus
      {
         if(_instance == null)
         {
            _instance = new ChangeViewStatus();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
      }
      
      public function changeViewStatus(param1:Object) : void
      {
         var _loc4_:Object = null;
         var _loc5_:PlayerBattleInfo = null;
         FightController.instance.desc = param1.desc;
         this.fightPanel.refreshTxt(FightController.instance.desc + " 。");
         this.fightPanel.canStart = true;
         this.fightPanel.whoSwitch = 1;
         var _loc2_:Boolean = false;
         var _loc3_:Array = param1.pmmList;
         for each(_loc4_ in _loc3_)
         {
            _loc5_ = new PlayerBattleInfo();
            _loc5_.parseInfo(_loc4_);
            _loc5_ = FightData.instance.setLocaId(_loc5_);
            if(PetBriefInfo(_loc5_.myPets[0]).id == PetBriefInfo(FightData.instance.playerInfo[_loc5_.slotId].myPets[0]).id)
            {
               _loc2_ = true;
            }
            PetBriefInfo(FightData.instance.playerInfo[_loc5_.slotId].myPets[0]).updateInfo(_loc5_.myPets[0]);
            PetBriefInfo(FightData.instance.playerInfo[_loc5_.slotId].myPets[0]).becomeNormalView();
            if(_loc2_)
            {
               this.switchPet(_loc5_.locaId,_loc5_.myPets[0]);
            }
         }
         if(!_loc2_)
         {
            this.fightPanel.canStart = false;
            this.fightPanel.whoSwitch = 0;
            FightController.instance.startHandle();
         }
      }
      
      private function switchPet(param1:int, param2:PetBriefInfo) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function showArmorBurstMovie(param1:MCPetContainer, param2:int, param3:Function) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function showEffectMovie(param1:MCPetContainer, param2:int, param3:Function) : void
      {
         var curMCPetContainer:MCPetContainer = null;
         var index:int = 0;
         var effectMovie:MovieClip = null;
         var changeMCPetContainer:MCPetContainer = param1;
         var locaId:int = param2;
         var callBack:Function = param3;
         curMCPetContainer = this.fightPanel.petMCList[locaId] as MCPetContainer;
         index = curMCPetContainer.parent.getChildIndex(curMCPetContainer);
         effectMovie = new ChangeViewEndMovie() as MovieClip;
         effectMovie.x = curMCPetContainer.x;
         effectMovie.y = curMCPetContainer.y;
         this.fightPanel.layerPet.addChildAt(effectMovie,index + 1);
         effectMovie.gotoAndPlay(1);
         FightMovieManager.instance.addMovie(effectMovie);
         effectMovie.addFrameScript(11,function():void
         {
            var tweenLiteVars:TweenLiteVars;
            var tweenMax:TweenMax = null;
            DisplayUtil.stopAndRemove(curMCPetContainer);
            changeMCPetContainer.x = curMCPetContainer.x;
            changeMCPetContainer.y = curMCPetContainer.y;
            fightPanel.petMCList[locaId] = changeMCPetContainer;
            fightPanel.layerPet.addChildAt(changeMCPetContainer,index);
            changeMCPetContainer.scaleX = 0;
            changeMCPetContainer.scaleY = 0;
            tweenLiteVars = new TweenLiteVars();
            tweenLiteVars.prop("scaleX",1);
            tweenLiteVars.prop("scaleY",1);
            tweenLiteVars.useFrames(true);
            tweenLiteVars.onComplete(function():void
            {
               FightTweenMaxManager.instance.removeTweenMax(tweenMax);
            });
            tweenMax = new TweenMax(changeMCPetContainer,25,tweenLiteVars);
            FightTweenMaxManager.instance.addTweenMax(tweenMax);
         });
         effectMovie.addFrameScript(effectMovie.totalFrames - 1,function():void
         {
            FightMovieManager.instance.removeMovie(effectMovie);
            DisplayUtil.stopAndRemove(effectMovie);
            callBack.apply();
         });
      }
      
      public function dispose() : void
      {
         this.fightPanel = null;
         _instance = null;
      }
   }
}

