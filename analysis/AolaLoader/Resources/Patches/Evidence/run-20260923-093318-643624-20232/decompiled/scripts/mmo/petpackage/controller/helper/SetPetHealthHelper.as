package mmo.petpackage.controller.helper
{
   import mmo.common.dialog.NewDialog;
   import mmo.common.simplemoviehelper.ShowMovieOrCartoonHelper;
   import mmo.framework.comm.PetClient2;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.newbie.NewbieEvent;
   import mmo.interfaces.newbie.NewbieEventDispatcher;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   import mmo.petpackage.data.PetDetailDataMap;
   
   public class SetPetHealthHelper
   {
      
      private var pbi:PetBriefInfo = null;
      
      private var _index:int = -1;
      
      public function SetPetHealthHelper()
      {
         super();
      }
      
      public function tryHealthPet(param1:PetBriefInfo, param2:int) : void
      {
         this.pbi = param1;
         if(PetDetailDataMap.instance.checkCache(this.pbi.id))
         {
            this.pbi = PetDetailDataMap.instance.getPetDetailInfo(this.pbi.id);
         }
         this._index = param2;
         this.health();
      }
      
      private function showJingBiRecureConfirmPanel(param1:Function) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function checkSkillPP() : Boolean
      {
         var _loc2_:SkillInfo = null;
         var _loc1_:Array = this.pbi.skills;
         for each(_loc2_ in _loc1_)
         {
            if(_loc2_.canUseTimes < _loc2_.maxUseTimes)
            {
               return false;
            }
         }
         return true;
      }
      
      private function health() : void
      {
         NewbieEventDispatcher.getInstance().dispatchEvent(new NewbieEvent("addPetHpSingle",{}));
         SocketClient.instance.addEventListener(PetClient2.RSPN_PM_REVEAL_HP,this.onSocketHealthPet);
         PetClient2.instance.pmRevealAllHp();
      }
      
      private function onSocketHealthPet(param1:SocketClientEvent) : void
      {
         var _loc3_:int = 0;
         var _loc2_:Boolean = Boolean(param1.params.res);
         SocketClient.instance.removeEventListener(PetClient2.RSPN_PM_REVEAL_HP,this.onSocketHealthPet);
         if(_loc2_)
         {
            _loc3_ = int(param1.params.pi);
            PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_SINGLE_HEALTH,{
               "pi":_loc3_,
               "index":this._index
            }));
            this.playRecoverMovie();
         }
         else
         {
            NewDialog.showSucceedMessage("恢复失败！");
         }
      }
      
      private function playRecoverMovie() : void
      {
         var _loc1_:String = "pet/packagepetrecovermovie";
         var _loc2_:String = "mmo.petpackage.view.PackagePetRecoverMovie";
         ShowMovieOrCartoonHelper.showMovieOrCartoon(true,_loc1_,_loc2_,null,"",true,true);
      }
   }
}

