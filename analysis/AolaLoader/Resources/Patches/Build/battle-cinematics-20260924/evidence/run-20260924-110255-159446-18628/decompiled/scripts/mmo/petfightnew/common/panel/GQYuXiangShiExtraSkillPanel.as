package mmo.petfightnew.common.panel
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.pet.ActPetHelper;
   
   public class GQYuXiangShiExtraSkillPanel extends MovieClip
   {
      
      private static const MaxPetNum:int = 3;
      
      private var _pbi:PetBriefInfo = null;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _pmData:PMData;
      
      private var _res:MovieClip;
      
      private var _skillId:int;
      
      private var _canChangeObjArr:Array = [];
      
      public function GQYuXiangShiExtraSkillPanel(param1:PetBriefInfo, param2:MovieClip, param3:int)
      {
         super();
         this._pbi = param1;
         this._res = param2;
         this._skillId = param3;
         this._pmData = this._pmSvr.getOperationPM(this._pbi.raceId).pmData;
         this.refresh();
         this._res.addEventListener(MouseEvent.CLICK,this.onClickPet);
      }
      
      public function setClickable(param1:Boolean) : void
      {
      }
      
      public function refresh() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:MovieClip = null;
         var _loc4_:int = 0;
         this._canChangeObjArr = StatusUtil.getYuXiangShiCanChangObjArr(this._pbi);
         var _loc1_:int = 0;
         while(_loc1_ < MaxPetNum)
         {
            _loc2_ = ActComHelper.getChildNode(this._res,"mcPet_" + _loc1_) as MovieClip;
            if(_loc1_ < this._canChangeObjArr.length)
            {
               _loc2_.visible = true;
               _loc3_ = ActComHelper.getChildNode(_loc2_,"mcView") as MovieClip;
               ActPetHelper.setPetIcon(_loc3_,0,PetIconType.FIGHT);
               ActPetHelper.setPetIcon(_loc3_,this._canChangeObjArr[_loc1_].raceId,PetIconType.FIGHT);
               _loc4_ = StatusUtil.getYuXiangShiSecondSkillCd(this._pbi);
               if(_loc4_ > 0)
               {
                  ActComHelper.refreshObj(this._res,"mcPet_" + _loc1_,true,_loc4_ + "回合后方可使用");
               }
               else
               {
                  ActComHelper.refreshObj(this._res,"mcPet_" + _loc1_,false);
               }
            }
            else
            {
               _loc2_.visible = false;
            }
            _loc1_++;
         }
      }
      
      private function onClickPet(param1:MouseEvent) : void
      {
         var _loc3_:int = 0;
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnPet")
         {
            if(StatusUtil.getYuXiangShiSecondSkillCd(this._pbi) > 0)
            {
               return;
            }
            _loc3_ = int(ActComHelper.moreIntelligentlyGetIndex(param1.target as DisplayObject,1)[0]);
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FightUseCustomSkill,{
               "skillId":this._skillId,
               "index":this._canChangeObjArr[_loc3_].uniqueId
            }));
         }
      }
      
      public function dispose() : void
      {
         if(this._res)
         {
            this._res.removeEventListener(MouseEvent.CLICK,this.onClickPet);
         }
      }
   }
}

