package mmo.petfightnew.common.fightcontroller
{
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.util.BSUtil;
   
   public class Status implements IDispose
   {
      
      private static var _instance:Status;
      
      private var fightPanel:FightPanel;
      
      private var _isFirstPrintTurn:Boolean = true;
      
      public function Status()
      {
         super();
      }
      
      public static function get instance() : Status
      {
         if(_instance == null)
         {
            _instance = new Status();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
      }
      
      public function status(param1:Object) : void
      {
         var pmmList:Array = null;
         var kListPmmStatuses:Array = null;
         var pmmStatuseObj:Object = null;
         var pmmStatuses:Array = null;
         var obj:Object = null;
         var bs:String = null;
         var bus:Array = null;
         var playerInfo:PlayerBattleInfo = null;
         var status:String = null;
         var hpIncList:String = null;
         var shp:String = null;
         var skillWindWordList:Array = null;
         var killList:Object = null;
         var o:Object = null;
         var isReplace:Boolean = false;
         var params:Object = param1;
         try
         {
            pmmList = params.pmmList;
            FightController.instance.desc = params.desc;
            kListPmmStatuses = [];
            for each(pmmStatuseObj in FightController.instance.pmmStatuses)
            {
               if(pmmStatuseObj.killList != null && pmmStatuseObj.killList.length > 0)
               {
                  kListPmmStatuses.push(pmmStatuseObj);
               }
            }
            FightController.instance.pmmStatuses = kListPmmStatuses;
            pmmStatuses = [];
            for each(obj in pmmList)
            {
               playerInfo = new PlayerBattleInfo();
               playerInfo.parseInfo(obj);
               playerInfo = FightData.instance.setLocaId(playerInfo);
               if(playerInfo != null && FightData.instance.playerInfo[playerInfo.slotId] != null && FightData.instance.playerInfo[playerInfo.slotId].myPets[0] != null)
               {
                  FightData.instance.playerInfo[playerInfo.slotId].myPets[0].updateInfo(playerInfo.myPets[0]);
                  status = PetBriefInfo(playerInfo.myPets[0]).status;
                  hpIncList = obj.hpIncList || "";
                  shp = obj.shp || "";
                  skillWindWordList = obj.cbl || [];
                  killList = obj.kList || {};
                  o = {
                     "hpInc":obj.hpInc,
                     "player":playerInfo,
                     "srt":obj.srt,
                     "aor":0,
                     "cri":obj.cri,
                     "isStatus":true,
                     "status":status,
                     "hpIncList":hpIncList.split(","),
                     "ifShowStateMovie":false,
                     "hpType":obj.hpType,
                     "shp":shp.split(","),
                     "skillWindWordList":skillWindWordList,
                     "killList":killList
                  };
                  isReplace = false;
                  for each(pmmStatuseObj in FightController.instance.pmmStatuses)
                  {
                     if((pmmStatuseObj.player as PlayerBattleInfo).locaId == playerInfo.locaId)
                     {
                        pmmStatuseObj = o;
                        isReplace = true;
                     }
                  }
                  if(!isReplace)
                  {
                     FightController.instance.pmmStatuses.push(o);
                  }
                  pmmStatuses.push(o);
               }
            }
            bs = BSUtil.parseBS(params.bs);
            this.fightPanel.setBS(bs);
            bus = BSUtil.parseBackGroundUp(params.bs);
            this.fightPanel.setBackGroundUp(bus);
            this.fightPanel.setPetUp(params);
            this.fightPanel.refreshInfos(pmmStatuses);
            if(FightController.instance.turnCount <= 0 && this._isFirstPrintTurn)
            {
               this.fightPanel.refreshTxt("<font color = \'#b7dcff\'> " + "第1回合" + "</font>");
               this._isFirstPrintTurn = false;
               CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("OnfightStart",{"params":params}));
            }
            this.fightPanel.refreshTxt(FightController.instance.desc);
            if(pmmList.length != 0)
            {
               FightController.instance.startHandle();
            }
         }
         catch(e:Error)
         {
            bs = BSUtil.parseBS(params.bs);
            fightPanel.setBS(bs);
            bus = BSUtil.parseBackGroundUp(params.bs);
            fightPanel.setBackGroundUp(bus);
            fightPanel.setPetUp(params);
            fightPanel.refreshInfos(FightController.instance.pmmStatuses);
            fightPanel.refreshTxt(FightController.instance.desc);
            FightController.instance.startHandle();
         }
      }
      
      public function dispose() : void
      {
         this.fightPanel = null;
         _instance = null;
      }
   }
}

