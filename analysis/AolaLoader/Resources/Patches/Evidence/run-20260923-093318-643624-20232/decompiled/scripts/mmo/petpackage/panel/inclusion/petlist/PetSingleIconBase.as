package mmo.petpackage.panel.inclusion.petlist
{
   import flash.display.MovieClip;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.data.custom.PMData;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petpackage.data.PetDetailDataMap;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.pet.petlabel.PetLabelConfig;
   import mmo.play.pet.petlabel.PetLabelIconHelper;
   
   public class PetSingleIconBase extends MovieClip implements IDispose
   {
      
      public var detail:PetSingleIconDetail;
      
      public var mcPetLabel:MovieClip;
      
      public var mc_hp:MovieClip;
      
      public var mc_select:MovieClip;
      
      public var mcadd:MovieClip;
      
      public var mcnormal:MovieClip;
      
      private var _objData:Object = null;
      
      private var _mcDetail:PetSingleIconDetail = null;
      
      private var mcHp:MovieClip = null;
      
      private var mcSelect:MovieClip = null;
      
      private var mcAdd:MovieClip;
      
      private var mcNormal:MovieClip;
      
      public function PetSingleIconBase()
      {
         super();
         this._mcDetail = this.detail as PetSingleIconDetail;
         this.mcSelect = this.mc_select as MovieClip;
         this.mcHp = this.mc_hp as MovieClip;
         this.mcSelect.visible = false;
         this.mcAdd = this.mcadd as MovieClip;
         this.mcNormal = this.mcnormal as MovieClip;
      }
      
      public function dispose() : void
      {
         this._mcDetail && this._mcDetail.dispose();
         this._mcDetail = null;
      }
      
      public function nullPet() : void
      {
         this.mouseChildren = false;
         this._mcDetail.visible = false;
         this.mcHp.visible = false;
         this.mcAdd.visible = true;
         this._objData = null;
         this.mcNormal.gotoAndStop(1);
         var _loc1_:MovieClip = ActComHelper.getChildNode(this,"mcPetLabel") as MovieClip;
         PetLabelIconHelper.clearLabelIcon(_loc1_);
      }
      
      public function setData(param1:Object) : void
      {
         this._mcDetail.visible = true;
         this._objData = param1;
         this.updateUI();
      }
      
      public function get objData() : Object
      {
         return this._objData;
      }
      
      public function set objData(param1:Object) : void
      {
         this._objData = param1;
      }
      
      public function get id() : int
      {
         if(null == this._objData)
         {
            return -1;
         }
         return this._objData.pmSView.i;
      }
      
      public function set selected(param1:Boolean) : void
      {
         this.mcSelect.visible = param1;
      }
      
      public function get selected() : Boolean
      {
         return this.mcSelect.visible;
      }
      
      private function updateUI() : void
      {
         var pmService:IPMService;
         var pmData:PMData;
         var petlabelContainer:MovieClip;
         var pbi:PetBriefInfo = null;
         var frame:int = 0;
         var errorInfo:String = null;
         pbi = new PetBriefInfo();
         pbi.parseInfo(this._objData);
         if(PetDetailDataMap.instance.checkCache(pbi.id))
         {
            pbi = PetDetailDataMap.instance.getPetDetailInfo(pbi.id);
         }
         this._mcDetail.setData(this._objData,pbi);
         this.mcHp.visible = true;
         this.mcHp.gotoAndStop(int(this.mcHp.totalFrames * pbi.curHp / pbi.maxHp));
         this.mcAdd.visible = false;
         pmService = ServiceContainer.getService(IPMService) as IPMService;
         pmData = pmService.customData.pmDataMap.getPM(pbi.raceId);
         petlabelContainer = ActComHelper.getChildNode(this,"mcPetLabel") as MovieClip;
         PetLabelIconHelper.loadIconByRaceId(pbi.raceId,petlabelContainer,PetLabelConfig.LevelType_1,0.7);
         try
         {
            frame = 0;
            if(pmData.isXinghuiPM())
            {
               frame = 6;
            }
            else if(pmData.isDegeneratorPM())
            {
               frame = 6;
            }
            else if(pmData.isLegendPM())
            {
               frame = 5;
            }
            else if(pmData.isCompletePM())
            {
               frame = 4;
            }
            else if(pbi.isGetAoYiSkill)
            {
               frame = 2;
            }
            else if(pmData.isMiraclePet())
            {
               frame = 3;
            }
            else
            {
               frame = 1;
            }
            this.mcSelect.gotoAndStop(frame);
            this.mcNormal.gotoAndStop(frame);
         }
         catch(e:Error)
         {
            errorInfo = "亚比的raceId：" + pbi.raceId + "\n亚比的pmId：" + pbi.id + "\n";
         }
      }
   }
}

