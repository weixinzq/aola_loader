package mmo.petfightnew.common.panel
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.panel.skill.GQSmallSkillComponent;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.actthings.helper.ActComHelper;
   
   public class GQShenYuTianGangExtraSkillPanel extends MovieClip
   {
      
      private static const MaxSkillNum:int = 4;
      
      private var _pbi:PetBriefInfo = null;
      
      private var _pmSvr:IPMService = ServicePool.instance.getService(IPMService);
      
      private var _pmData:PMData;
      
      private var _pskSvr:IPetSkillMesService = null;
      
      private var _skillIdList:Array = [];
      
      private var _res:MovieClip;
      
      private var _skillComponentList:Array = [];
      
      public function GQShenYuTianGangExtraSkillPanel(param1:PetBriefInfo, param2:MovieClip)
      {
         super();
         this._pbi = param1;
         this._res = param2;
         this._pmData = this._pmSvr.getOperationPM(this._pbi.raceId).pmData;
         this._pskSvr = ServicePool.instance.getService(IPetSkillMesService);
         this._skillIdList = StatusUtil.getShenYuTianGangExtraSkillIds(this._pbi);
         this.refresh();
         this._res.addEventListener(MouseEvent.CLICK,this.onClickSkill);
      }
      
      public function setClickable(param1:Boolean) : void
      {
      }
      
      public function refresh() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:PMSkill = null;
         var _loc4_:GQSmallSkillComponent = null;
         var _loc5_:* = undefined;
         var _loc1_:int = 0;
         while(_loc1_ < MaxSkillNum)
         {
            _loc2_ = this._res.getChildByName("mcskill_" + _loc1_) as MovieClip;
            if(this._skillIdList.length > _loc1_ && this._skillIdList[_loc1_] > 0)
            {
               _loc2_.visible = true;
               _loc3_ = this._pmSvr.customData.pmSkillMap.getSkill(this._skillIdList[_loc1_]);
               if(this._skillComponentList.length <= _loc1_)
               {
                  _loc4_ = new GQSmallSkillComponent(this._pbi.raceId,_loc2_,this._pbi);
                  this._skillComponentList.push(_loc4_);
               }
               else
               {
                  _loc4_ = this._skillComponentList[_loc1_];
               }
               _loc5_ = new SkillInfo();
               _loc5_.parseInfo({
                  "id":_loc3_.skillId,
                  "name":_loc3_.newCnName,
                  "pp":_loc3_.allPP + "/" + _loc3_.allPP,
                  "ssi":0,
                  "_used":false
               });
               _loc4_.refresh(_loc5_);
            }
            else
            {
               _loc2_.visible = false;
            }
            _loc1_++;
         }
      }
      
      private function onClickSkill(param1:MouseEvent) : void
      {
         var _loc3_:int = 0;
         var _loc2_:String = param1.target.name;
         if(_loc2_.indexOf("btnSkill") != -1)
         {
            _loc3_ = int(ActComHelper.moreIntelligentlyGetIndex(param1.target as DisplayObject,1)[0]);
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FightUseCustomSkill,{"skillId":this._skillIdList[_loc3_]}));
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:int = 0;
         while(_loc1_ < this._skillComponentList.length)
         {
            this._skillComponentList[_loc1_].dispose();
            _loc1_++;
         }
         this._skillComponentList = [];
         this._res.removeEventListener(MouseEvent.CLICK,this.onClickSkill);
      }
   }
}

