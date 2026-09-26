package mmo.petfightnew.common.ui
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.panel.OperableView;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.pet.ActPetHelper;
   
   public class GQXiYaFightIcon extends OperableView
   {
      
      private static const MaxPetNum:int = 2;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _gameOptionSvr:IGameOptionService = ServicePool.instance.getService(IGameOptionService);
      
      private var _pbi:PetBriefInfo;
      
      private var _iconMc:MovieClip;
      
      public function GQXiYaFightIcon(param1:MovieClip)
      {
         super(param1);
         this.init();
      }
      
      override protected function initComponents() : void
      {
         super.initComponents();
      }
      
      override protected function addClickFuncs() : void
      {
         super.addClickFuncs();
         this.regClickFunc("btnPet",this.clickPet,true);
      }
      
      public function refresh(param1:PetBriefInfo) : void
      {
         var _loc3_:Object = null;
         var _loc4_:int = 0;
         var _loc5_:MovieClip = null;
         if(!param1)
         {
            if(!this._pbi)
            {
               DisplayUtil.stop(this._view);
               this.setVisible("",false);
               return;
            }
            param1 = this._pbi;
         }
         else
         {
            this._pbi = param1;
         }
         var _loc2_:Boolean = StatusUtil.getIsInXiYaFightState(this._pbi);
         if(_loc2_)
         {
            this.setVisible("",true);
            _loc3_ = StatusUtil.getXiYaFightCanChangObjArr(this._pbi);
            _loc4_ = 0;
            while(_loc4_ < MaxPetNum)
            {
               _loc5_ = this.getChild("mcPet_" + _loc4_) as MovieClip;
               if(_loc4_ < _loc3_.length)
               {
                  _loc5_.visible = true;
                  ActPetHelper.setPetIcon(ActComHelper.getChildNode(_loc5_,"mcView") as MovieClip,_loc3_[_loc4_].raceId,PetIconType.FIGHT);
               }
               else
               {
                  _loc5_.visible = false;
               }
               _loc4_++;
            }
         }
         else
         {
            this._pbi = null;
            DisplayUtil.stop(this._view);
            this.setVisible("",false);
         }
      }
      
      override protected function refreshView() : void
      {
         super.refreshView();
         DisplayUtil.stop(this._view);
         this.setVisible("",false);
      }
      
      private function clickPet(param1:DisplayObject) : void
      {
         var _loc2_:Object = StatusUtil.getXiYaFightCanChangObjArr(this._pbi);
         var _loc3_:int = int(this.intelligentlyGetIndex(param1));
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FightUseCustomSkill,{
            "skillId":400164,
            "index":_loc2_[_loc3_].uniqueId
         }));
      }
      
      override public function dispose() : void
      {
         super.dispose();
      }
   }
}

